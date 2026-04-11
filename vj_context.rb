class VJContext
  def initialize(beat:, audio: nil)
    @beat       = beat
    @audio      = audio
    @started_at = Time.now
    @frame      = 0
  end

  def update
    @frame += 1
  end

  def phase = @beat.phase
  def bpm   = @beat.bpm
  def count = @beat.count
  def beat? = @audio ? @audio.beat? : @beat.beat?

  def amp = @audio&.amp || 0.0
  def low = @audio&.low || 0.0
  def mid = @audio&.mid || 0.0
  def hi  = @audio&.hi  || 0.0

  def t     = (Time.now - @started_at).to_f
  def frame = @frame
end
