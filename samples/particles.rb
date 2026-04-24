class RuVJ
  @@particles ||= Particles.new(max: 500)

  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0.02})
    @@particles.emit(
      x: 0, y: 0,
      speed: 0.15 + @vj.amp * 0.3,
      life: 90,
      hue: (Time.now.to_f * 60) % 360,
      size: 0.15,
      n: 3
    ) if @vj.beat?
    @@particles.update
    @@particles.draw
  end
end
