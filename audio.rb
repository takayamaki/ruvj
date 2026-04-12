require 'timeout'

class Audio
  SAMPLE_RATE        = 48000
  CHUNK_SIZE         = 1024
  ENERGY_FRAMES      = 43
  CALIBRATION_CHUNKS = 23   # ~500ms (48000/1024 ≈ 47 chunks/sec)

  attr_reader :amp, :low, :mid, :hi, :source, :spectrum, :waveform

  def initialize(beat_fallback:)
    @beat_fallback = beat_fallback
    @amp = @low = @mid = @hi = 0.0
    @spectrum = []
    @waveform = []
    @spec_calib = nil
    @beat_detected = false
    @amp_floor = @low_floor = @mid_floor = @hi_floor = 0.0
    @amp_calib = @low_calib = @mid_calib = @hi_calib = 0.0
    @amp_peak  = @low_peak  = @mid_peak  = @hi_peak  = 0.001
    @calib_count = 0
    @mutex  = Mutex.new
    @source = :beat
    start_mic
  end

  def update
    sync_from_beat if @source == :beat
  end

  def beat?
    @mutex.synchronize do
      flag = @beat_detected
      @beat_detected = false
      flag
    end
  end

  private

  def start_mic
    cmd = "rec -q -t raw -e signed-integer -b 16 -c 1 -r #{SAMPLE_RATE} -"
    @io = IO.popen(cmd, 'rb')
    @result_port  = Ractor::Port.new
    @proc_ractor  = build_proc_ractor
    @source = :mic
    Thread.new { mic_loop }
    Thread.new { result_loop }
  rescue => e
    $stderr.puts "mic unavailable: #{e.message}"
  end

  def build_proc_ractor
    Ractor.new(@result_port, SAMPLE_RATE, CHUNK_SIZE, ENERGY_FRAMES) do |result_port, sr, cs, ef|
      energy_history = Array.new(ef, 0.0)
      bin    = sr.to_f / cs
      low_hi = (150  / bin).ceil
      mid_hi = (4000 / bin).ceil

      # ツイドルファクタとビット反転テーブルをチャンクループ前に事前計算
      # Complex オブジェクトを避けて実部・虚部を別々の Float 配列で保持（GC セグフォ回避）
      log2n      = Math.log2(cs).to_i
      twiddle_re = (0...log2n).map do |stage|
        half  = 1 << stage
        len   = half << 1
        angle = -2.0 * Math::PI / len
        Array.new(half) { |k| Math.cos(angle * k) }
      end
      twiddle_im = (0...log2n).map do |stage|
        half  = 1 << stage
        len   = half << 1
        angle = -2.0 * Math::PI / len
        Array.new(half) { |k| Math.sin(angle * k) }
      end
      bit_rev = Array.new(cs) do |i|
        rev = 0
        log2n.times { |b| rev = (rev << 1) | ((i >> b) & 1) }
        rev
      end

      fft = ->(samples) do
        re = Array.new(cs) { |i| samples[i].to_f }
        im = Array.new(cs, 0.0)
        cs.times { |i| re[i], re[bit_rev[i]] = re[bit_rev[i]], re[i] if i < bit_rev[i] }
        cs.times { |i| im[i], im[bit_rev[i]] = im[bit_rev[i]], im[i] if i < bit_rev[i] }
        log2n.times do |stage|
          half = 1 << stage
          len  = half << 1
          twr  = twiddle_re[stage]
          twi  = twiddle_im[stage]
          (0...cs).step(len) do |i|
            half.times do |k|
              p = i + k
              q = p + half
              vr = re[q] * twr[k] - im[q] * twi[k]
              vi = re[q] * twi[k] + im[q] * twr[k]
              re[q] = re[p] - vr
              im[q] = im[p] - vi
              re[p] = re[p] + vr
              im[p] = im[p] + vi
            end
          end
        end
        Array.new(cs / 2) { |k| Math.sqrt(re[k] * re[k] + im[k] * im[k]) }
      end

      band_rms = ->(spectrum, from, to) do
        bins = spectrum[from..to]
        return 0.0 if bins.nil? || bins.empty?
        Math.sqrt(bins.sum { _1 * _1 } / bins.size)
      end

      loop do
        samples = Ractor.receive

        rms      = Math.sqrt(samples.sum { _1 * _1 } / samples.size)
        spectrum = fft.(samples)
        step     = cs / 256
        waveform = Array.new(256) { |i| samples[i * step] }

        low = band_rms.(spectrum, 1,      low_hi)
        mid = band_rms.(spectrum, low_hi, mid_hi)
        hi  = band_rms.(spectrum, mid_hi, spectrum.size - 1)

        energy = rms ** 2
        energy_history.shift
        energy_history.push(energy)
        avg  = energy_history.sum / energy_history.size
        beat = energy > avg * 1.4 && energy > 0.005

        result_port << { rms: rms, low: low, mid: mid, hi: hi, beat: beat, spectrum: spectrum, waveform: waveform }
      end
    end
  end

  def mic_loop
    bytes = CHUNK_SIZE * 2
    loop do
      raw = @io.read(bytes)
      break if raw.nil? || raw.size < bytes
      @proc_ractor.send(raw.unpack('s<*').map { _1 / 32768.0 }, move: true)
    end
  rescue => e
    $stderr.puts "mic error: #{e.message}"
    @source = :beat
  end

  CHUNK_BUDGET = CHUNK_SIZE.to_f / SAMPLE_RATE  # ~21ms

  def result_loop
    loop do
      begin
        apply_result(Timeout.timeout(CHUNK_BUDGET) { @result_port.receive })
      rescue Timeout::Error
        # バジェット超過: 前フレームの値をそのまま保持
      end
    end
  rescue => e
    $stderr.puts "result error: #{e.message}"
  end

  def apply_result(r)
    @mutex.synchronize do
      rms  = r[:rms]
      low  = r[:low]
      mid  = r[:mid]
      hi   = r[:hi]
      beat = r[:beat]
      spec = r[:spectrum]

      @amp_floor = @amp_floor * 0.998 + rms * 0.002
      @low_floor = @low_floor * 0.998 + low * 0.002
      @mid_floor = @mid_floor * 0.998 + mid * 0.002
      @hi_floor  = @hi_floor  * 0.998 + hi  * 0.002

      amp_var = [rms - @amp_floor, 0.0].max
      low_var = [low - @low_floor, 0.0].max
      mid_var = [mid - @mid_floor, 0.0].max
      hi_var  = [hi  - @hi_floor,  0.0].max

      if @calib_count < CALIBRATION_CHUNKS
        @amp_calib = [@amp_calib, amp_var].max
        @low_calib = [@low_calib, low_var].max
        @mid_calib = [@mid_calib, mid_var].max
        @hi_calib  = [@hi_calib,  hi_var ].max
        if @spec_calib
          spec.size.times { |k| @spec_calib[k] = [@spec_calib[k], spec[k]].max }
        else
          @spec_calib = spec.dup
        end
        @calib_count += 1
        if @calib_count == CALIBRATION_CHUNKS
          $stderr.puts "calibrated: low=#{@low_calib.round(4)} mid=#{@mid_calib.round(4)} hi=#{@hi_calib.round(4)}"
        end
      else
        amp_sig = [amp_var - @amp_calib, 0.0].max
        low_sig = [low_var - @low_calib, 0.0].max
        mid_sig = [mid_var - @mid_calib, 0.0].max
        hi_sig  = [hi_var  - @hi_calib,  0.0].max

        @amp_peak = [@amp_peak * 0.995, amp_sig].max
        @low_peak = [@low_peak * 0.995, low_sig].max
        @mid_peak = [@mid_peak * 0.995, mid_sig].max
        @hi_peak  = [@hi_peak  * 0.995, hi_sig ].max

        @amp = smoothstep(amp_sig / [@amp_peak, 0.001].max)
        @low = smoothstep(low_sig / [@low_peak, 0.001].max)
        @mid = smoothstep(mid_sig / [@mid_peak, 0.001].max)
        @hi  = smoothstep(hi_sig  / [@hi_peak,  0.001].max)
        @beat_detected = beat
        @spectrum = Array.new(spec.size) { |k| [spec[k] - @spec_calib[k], 0.0].max }
        @waveform = r[:waveform]
      end
    end
  end

  def smoothstep(x)
    t = x.clamp(0.0, 1.0)
    t * t * (3.0 - 2.0 * t)
  end

  def sync_from_beat
    ph = @beat_fallback.phase
    @amp = 0.5 + Math.sin(ph * Math::PI) * 0.3
    @low = [1.0 - ph * 3, 0.0].max
    @mid = ph
    @hi  = Math.sin(ph * Math::PI * 4).abs * 0.3
    @mutex.synchronize { @beat_detected = @beat_fallback.beat? }
  end
end
