module VjEffects
  module Spectrum
    def Spectrum(n: 32, x: 0, y: -8, width: 24, height: 6, hue: 200, sat: 0.8, val: 1.0, alpha: 255, gap: 0.1, z: 0)
      bars  = @vj.spectrum(n)
      bar_w = width.to_f / n
      bars.each_with_index do |v, i|
        h = v * height
        next if h <= 0
        bx = x - width / 2.0 + bar_w * (i + 0.5)
        Rect(x: bx, y: y + h / 2.0, w: bar_w - gap, h: h, color: {h: hue, s: sat, v: val, a: alpha}, z: z)
      end
    end
  end
end
