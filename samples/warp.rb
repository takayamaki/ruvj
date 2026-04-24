class RuVJ
  @@warp ||= Warp.new(max: 300)

  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0})
    Kaleidoscope() do
    @@warp.step(
      r_min: 2,
      density: 5,
      speed: 0.05 + @vj.amp * 0.1,
      accel: 1.04,
      bold: 15,
      color: {h: (Time.now.to_f * 30) % 360, s: 1, v: 1}
    )
    end
  end
end
