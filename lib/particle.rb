require_relative 'vj_shapes'
require_relative 'renderer/base'

class ParticleSystem
  include VjShapes

  Particle = Struct.new(:x, :y, :vx, :vy, :life, :max_life, :hue, :size)

  def initialize(max: 300)
    @particles = []
    @max = max
  end

  def emit(x: 0, y: 0, speed: 0.15, life: 90, hue: 0, size: 0.2, n: 1)
    n.times do
      break if @particles.size >= @max
      angle = rand * Math::PI * 2
      v = rand * speed
      @particles << Particle.new(
        x, y,
        Math.cos(angle) * v,
        Math.sin(angle) * v,
        life, life, hue, size
      )
    end
  end

  def update
    @particles.each do |p|
      p.x    += p.vx
      p.y    += p.vy
      p.vy   -= 0.003  # 重力（VJ座標系はy上向きなので減算が下向き重力）
      p.life -= 1
    end
    @particles.reject! { |p| p.life <= 0 }
  end

  def draw(z: 0)
    @particles.each do |p|
      alpha = (255 * p.life / p.max_life).to_i
      Circle(x: p.x, y: p.y, r: p.size, color: {h: p.hue, s: 1, v: 1, a: alpha}, z: z)
    end
  end
end
