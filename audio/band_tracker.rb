class Audio
  BandTracker = Struct.new(:floor, :calib, :peak, :val) do
    def track_floor(raw)
      self.floor = floor * 0.998 + raw * 0.002
      [raw - floor, 0.0].max
    end

    def calibrate(var)
      self.calib = [calib, var].max
    end

    def process(var)
      sig = [var - calib, 0.0].max
      self.peak = [peak * 0.995, sig].max
      t = (sig / [peak, 0.001].max).clamp(0.0, 1.0)
      self.val = t * t * (3.0 - 2.0 * t)
    end
  end
end
