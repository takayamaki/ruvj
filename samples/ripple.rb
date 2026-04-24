class RuVJ
  @@ripples ||= Ripple.new(max: 20, speed: 0.2, life: 60)

  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0.02})
    hue = (@vj.t * 60) % 360
    @@ripples.update(emit: @vj.beat?) do |r:, alpha:|
      Ring(x: 0, y: @vj.low, r:, color: {h: hue, s: 1, v: 1, a: alpha})
    end
  end
end
