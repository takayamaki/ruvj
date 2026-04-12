require 'timeout'

class Audio
  # マイク入力・FFT・バンド計算を担うプロセッサ
  # 結果は on_result コールバックで Audio 側に渡す
  class Processor
    CHUNK_BUDGET = CHUNK_SIZE.to_f / SAMPLE_RATE  # ~21ms

    def initialize(on_result:)
      @on_result = on_result
      @active    = false
      start_mic
    end

    def active? = @active

    private

    def start_mic
      cmd = "rec -q -t raw -e signed-integer -b 16 -c 1 -r #{SAMPLE_RATE} -"
      @io          = IO.popen(cmd, 'rb')
      @result_port = Ractor::Port.new
      @proc_ractor = build_proc_ractor
      @active      = true
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
          samples  = Ractor.receive
          rms      = Math.sqrt(samples.sum { _1 * _1 } / samples.size)
          spectrum = fft.(samples)
          step     = cs / 256
          waveform = Array.new(256) { |i| samples[i * step] }
          low      = band_rms.(spectrum, 1,      low_hi)
          mid      = band_rms.(spectrum, low_hi, mid_hi)
          hi       = band_rms.(spectrum, mid_hi, spectrum.size - 1)

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
      @active = false
    end

    def result_loop
      loop do
        begin
          @on_result.call(Timeout.timeout(CHUNK_BUDGET) { @result_port.receive })
        rescue Timeout::Error
          # バジェット超過: 前フレームの値をそのまま保持
        end
      end
    rescue => e
      $stderr.puts "result error: #{e.message}"
    end
  end
end
