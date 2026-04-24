class RuVJ
  def draw_scene
    Kaleidoscope(segments: 7) do
      Lissajous(a: (@vj.low * 10).to_i + 3, b: (@vj.amp * 10).to_i + 5, delta: 0, rx: 16, ry: 9, steps: 64, bold: 0, color: {})
    end 
  end
end
