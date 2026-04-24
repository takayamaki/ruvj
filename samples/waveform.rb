class RuVJ
  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0})
    n = @vj.waveform.size
    return if n < 2
    (n - 1).times do |i|
      x1 = -16.0 + 32.0 *  i      / (n - 1)
      x2 = -16.0 + 32.0 * (i + 1) / (n - 1)
      y1 = @vj.waveform[i]     * 6.0
      y2 = @vj.waveform[i + 1] * 6.0
      Line(x1: x1, y1: y1, x2: x2, y2: y2, bold: 4, color: {h: 180, s: 0.7, v: 1})
    end
  end
end
