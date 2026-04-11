class Beat
  DEFAULT_BPM     = 120.0
  MIN_BPM         = 40.0
  MAX_BPM         = 240.0
  MAX_TAP_INTERVAL = 3.0
  MAX_TAP_HISTORY  = 8

  attr_reader :phase, :count

  def initialize
    @bpm        = DEFAULT_BPM
    @phase      = 0.0
    @count      = 0
    @beat_flag  = false
    @last_time  = nil
    @tap_times  = []
  end

  def bpm
    @bpm
  end

  def bpm=(val)
    @bpm = val.clamp(MIN_BPM, MAX_BPM).to_f
  end

  def update(now = Time.now)
    @last_time ||= now
    elapsed = now - @last_time
    @last_time = now

    period = 60.0 / @bpm
    prev_phase = @phase
    @phase += elapsed / period
    if @phase >= 1.0
      @phase -= @phase.floor
      @count += 1
      @beat_flag = true
    else
      @beat_flag = false
    end
  end

  def tap!(now = Time.now)
    if @tap_times.last && (now - @tap_times.last) > MAX_TAP_INTERVAL
      @tap_times.clear
    end
    @tap_times << now
    @tap_times.shift while @tap_times.size > MAX_TAP_HISTORY

    if @tap_times.size >= 2
      intervals = @tap_times.each_cons(2).map { |a, b| b - a }
      self.bpm = 60.0 / (intervals.sum / intervals.size)
    end

    @phase     = 0.0
    @beat_flag = true
  end

  def beat?
    flag = @beat_flag
    @beat_flag = false
    flag
  end
end
