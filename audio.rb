class Audio
  SAMPLE_RATE        = 48000
  CHUNK_SIZE         = 1024
  ENERGY_FRAMES      = 43
  CALIBRATION_CHUNKS = 23   # ~500ms (48000/1024 ≈ 47 chunks/sec)
end

require_relative 'audio/band_tracker'
require_relative 'audio/processor'

class Audio

  attr_reader :amp, :low, :mid, :hi, :spectrum, :waveform

  def source = @processor.active? ? :mic : :beat

  def initialize(beat_fallback:)
    @beat_fallback = beat_fallback
    @amp = @low = @mid = @hi = 0.0
    @spectrum = []
    @waveform = []
    @spec_calib  = nil
    @beat_detected = false
    @bands = {
      amp: BandTracker.new(0.0, 0.0, 0.001, 0.0),
      low: BandTracker.new(0.0, 0.0, 0.001, 0.0),
      mid: BandTracker.new(0.0, 0.0, 0.001, 0.0),
      hi:  BandTracker.new(0.0, 0.0, 0.001, 0.0)
    }
    @calib_count = 0
    @mutex     = Mutex.new
    @processor = Processor.new(on_result: method(:apply_result))
  end

  def update
    sync_from_beat unless @processor.active?
  end

  def beat?
    @mutex.synchronize do
      flag = @beat_detected
      @beat_detected = false
      flag
    end
  end

  private

  def apply_result(r)
    @mutex.synchronize do
      raw  = { amp: r[:rms], low: r[:low], mid: r[:mid], hi: r[:hi] }
      spec = r[:spectrum]

      vars = {}
      raw.each { |band, val| vars[band] = @bands[band].track_floor(val) }

      if @calib_count < CALIBRATION_CHUNKS
        vars.each { |band, var| @bands[band].calibrate(var) }
        @spec_calib ||= Array.new(spec.size, 0.0)
        spec.size.times { |k| @spec_calib[k] = [@spec_calib[k], spec[k]].max }
        @calib_count += 1
        if @calib_count == CALIBRATION_CHUNKS
          b = @bands
          $stderr.puts "calibrated: low=#{b[:low].calib.round(4)} mid=#{b[:mid].calib.round(4)} hi=#{b[:hi].calib.round(4)}"
        end
      else
        vars.each { |band, var| @bands[band].process(var) }
        @amp = @bands[:amp].val
        @low = @bands[:low].val
        @mid = @bands[:mid].val
        @hi  = @bands[:hi].val
        @beat_detected = r[:beat]
        @spectrum = Array.new(spec.size) { |k| [spec[k] - @spec_calib[k], 0.0].max }
        @waveform = r[:waveform]
      end
    end
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
