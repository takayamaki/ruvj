class VJContext
  def initialize(beat:, audio: nil)
    @beat       = beat
    @audio      = audio
    @started_at = Time.now
    @frame      = 0
    @beat_flag  = false
    @beat_val   = 0.0
    @amp_val = @low_val = @mid_val = @hi_val = 0.0
  end

  def update
    @frame += 1
    fired      = @audio ? @audio.beat? : @beat.beat?
    @beat_flag = true if fired
    @beat_val  = fired ? 1.0 : @beat_val * 0.85

    @amp_val = [@audio&.amp || 0.0, @amp_val * 0.75].max
    @low_val = [@audio&.low || 0.0, @low_val * 0.75].max
    @mid_val = [@audio&.mid || 0.0, @mid_val * 0.75].max
    @hi_val  = [@audio&.hi  || 0.0, @hi_val  * 0.75].max
  end

  def beat?
    flag = @beat_flag
    @beat_flag = false
    flag
  end

  def beat  = @beat_val

  def phase = @beat.phase
  def bpm   = @beat.bpm
  def count = @beat.count

  def amp = @amp_val
  def low = @low_val
  def mid = @mid_val
  def hi  = @hi_val

  def t     = (Time.now - @started_at).to_f
  def frame = @frame

  def spectrum(n = 32)
    raw = @audio&.spectrum
    return Array.new(n, 0.0) unless raw && raw.size > 1

    bins = raw.size
    # ビンごとに独立したピーク追従（低域/高域の振幅差を均一化）
    @spec_bin_peaks ||= Array.new(bins, 0.001)
    bins.times { |k| @spec_bin_peaks[k] = [@spec_bin_peaks[k] * 0.995, raw[k], 0.001].max }
    normalized = Array.new(bins) { |k| (raw[k] / @spec_bin_peaks[k]).clamp(0.0, 1.0) }

    bin_hz   = Audio::SAMPLE_RATE.to_f / Audio::CHUNK_SIZE
    f_min    = bin_hz
    f_max    = bin_hz * (bins - 1)
    log_span = Math.log(f_max / f_min)

    Array.new(n) do |i|
      freq_lo = f_min * Math.exp(log_span * i.to_f / n)
      freq_hi = f_min * Math.exp(log_span * (i + 1.0) / n)
      b_lo    = [(freq_lo / bin_hz).floor, 1].max
      b_hi    = [(freq_hi / bin_hz).ceil, bins - 1].min
      b_hi    = b_lo if b_hi < b_lo
      slice   = normalized[b_lo..b_hi]
      smoothstep(slice.sum / slice.size)
    end
  end

  private

  def smoothstep(x)
    t = x.clamp(0.0, 1.0)
    t * t * (3.0 - 2.0 * t)
  end
end
