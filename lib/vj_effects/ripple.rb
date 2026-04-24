module VjEffects
  # ビート等のトリガで emit した波紋が半径を広げつつ寿命に応じて薄くなる表示を担う。
  # ブロックは 1 つの drop を描く雛形として渡し、update の中で全 drop について
  # block.call(r:, alpha:) を実行する。
  #
  # visual.rb 使用例:
  #   @@ripple ||= Ripple.new(max: 20, speed: 0.2, life: 60)
  #   def draw_scene
  #     @@ripple.update(emit: @vj.beat?) do |r:, alpha:|
  #       Ring(x: 0, y: 0, r: r, color: {h: 180, s: 1, v: 1, a: alpha})
  #     end
  #   end
  class Ripple
    Drop = Struct.new(:r, :life, :max_life)

    def initialize(max: 20, speed: 0.2, life: 60, r_start: 0.5)
      @drops   = []
      @max     = max
      @speed   = speed
      @life    = life
      @r_start = r_start
    end

    def update(emit: false, &block)
      @drops << Drop.new(@r_start, @life, @life) if emit && @drops.size < @max
      @drops.each { |d| d.r += @speed; d.life -= 1 }
      @drops.reject! { |d| d.life <= 0 }
      @drops.each do |d|
        alpha_mul = d.life.to_f / d.max_life
        block.call(r: d.r, alpha: (alpha_mul * 255).to_i)
      end
    end
  end
end
