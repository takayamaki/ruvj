class Audio
  SAMPLE_RATE         = 48000
  CHUNK_SIZE          = 1024
  ENERGY_FRAMES       = 43
  CALIBRATION_CHUNKS  = 23   # ~500ms (48000/1024 ≈ 47 chunks/sec)

  attr_reader :amp, :low, :mid, :hi, :source

  def initialize(beat_fallback:)
    @beat_fallback  = beat_fallback
    @amp = @low = @mid = @hi = 0.0
    @beat_detected  = false
    @energy_history = Array.new(ENERGY_FRAMES, 0.0)
    @amp_peak  = @low_peak  = @mid_peak  = @hi_peak  = 0.001
    @amp_floor = @low_floor = @mid_floor = @hi_floor = 0.0
    @amp_calib = @low_calib = @mid_calib = @hi_calib = 0.0
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
    @io     = IO.popen(cmd, 'rb')
    @source = :mic
    Thread.new { mic_loop }
  rescue => e
    $stderr.puts "mic unavailable: #{e.message}"
  end

  def mic_loop
    bytes = CHUNK_SIZE * 2
    loop do
      raw = @io.read(bytes)
      break if raw.nil? || raw.size < bytes
      process(raw.unpack('s<*').map { _1 / 32768.0 })
    end
  rescue => e
    $stderr.puts "mic error: #{e.message}"
    @source = :beat
  end

  def process(samples)
    rms      = Math.sqrt(samples.sum { _1 * _1 } / samples.size)
    spectrum = fft(samples).first(CHUNK_SIZE / 2).map(&:abs)

    bin  = SAMPLE_RATE.to_f / CHUNK_SIZE
    low  = band_rms(spectrum, 1,                  (250  / bin).ceil)
    mid  = band_rms(spectrum, (250  / bin).ceil,  (4000 / bin).ceil)
    hi   = band_rms(spectrum, (4000 / bin).ceil,  spectrum.size - 1)

    energy = rms ** 2
    @energy_history.shift
    @energy_history.push(energy)
    avg   = @energy_history.sum / @energy_history.size
    beat  = energy > avg * 1.4 && energy > 0.005

    @mutex.synchronize do
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
        @calib_count += 1
        $stderr.puts "calibrated: low=#{@low_calib.round(4)} mid=#{@mid_calib.round(4)} hi=#{@hi_calib.round(4)}" if @calib_count == CALIBRATION_CHUNKS
      else
        amp_sig = [amp_var - @amp_calib, 0.0].max
        low_sig = [low_var - @low_calib, 0.0].max
        mid_sig = [mid_var - @mid_calib, 0.0].max
        hi_sig  = [hi_var  - @hi_calib,  0.0].max

        @amp_peak = [@amp_peak * 0.995, amp_sig].max
        @low_peak = [@low_peak * 0.995, low_sig].max
        @mid_peak = [@mid_peak * 0.995, mid_sig].max
        @hi_peak  = [@hi_peak  * 0.995, hi_sig ].max

        @amp           = smoothstep(amp_sig / [@amp_peak, 0.001].max)
        @low           = smoothstep(low_sig / [@low_peak, 0.001].max)
        @mid           = smoothstep(mid_sig / [@mid_peak, 0.001].max)
        @hi            = smoothstep(hi_sig  / [@hi_peak,  0.001].max)
        @beat_detected = beat
      end
    end
  end

  def smoothstep(x)
    t = x.clamp(0.0, 1.0)
    t * t * (3.0 - 2.0 * t)
  end

  def band_rms(spectrum, from, to)
    bins = spectrum[from..to]
    return 0.0 if bins.nil? || bins.empty?
    Math.sqrt(bins.sum { _1 * _1 } / bins.size)
  end

  def sync_from_beat
    ph = @beat_fallback.phase
    @amp = 0.5 + Math.sin(ph * Math::PI) * 0.3
    @low = [1.0 - ph * 3, 0.0].max
    @mid = ph
    @hi  = Math.sin(ph * Math::PI * 4).abs * 0.3
    @mutex.synchronize { @beat_detected = @beat_fallback.beat? }
  end

  # Cooley-Tukey FFT（2のべき乗のみ）
  def fft(samples)
    n = samples.size
    return [Complex(samples[0])] if n == 1

    even = fft(samples.each_slice(2).map(&:first))
    odd  = fft(samples.each_slice(2).map(&:last))
    half = n / 2

    Array.new(n) do |k|
      t = Complex(Math.cos(-2 * Math::PI * k / n),
                  Math.sin(-2 * Math::PI * k / n)) * odd[k % half]
      even[k % half] + t
    end
  end
end
