class RuVJ
  @@trail ||= Trail.new(len: 60)

  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0})
    t = @vj.t
    @@trail.update do
      Circle(
        x: Math.sin(t * 2) * 10,
        y: Math.cos(t * 3) * 5,
        r: 0.4 + @vj.amp * 1.5,
        color: {h: (t * 60) % 360, s: 1, v: 1}
      )
    end
  end
end
