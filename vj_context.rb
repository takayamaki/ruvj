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
end
