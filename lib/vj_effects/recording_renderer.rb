module VjEffects
  # ブロック内の draw_* 呼び出しをコマンド列として記録し、後で target renderer に
  # alpha 倍率つきで再生できるレンダラ。Trail の過去フレーム fade 再生に使う。
  # transform 系 (translate/scale/rotate) は記録せず yield 素通し。
  class RecordingRenderer
    Cmd = Struct.new(:kind, :args)

    attr_reader :commands

    def initialize
      @commands = []
    end

    def draw_triangle(*a) = @commands << Cmd.new(:triangle, a)
    def draw_rect(*a)     = @commands << Cmd.new(:rect,     a)
    def draw_line(*a)     = @commands << Cmd.new(:line,     a)
    def draw_text(*a)     = @commands << Cmd.new(:text,     a)

    def translate(_x, _y, &block)              = block.call
    def scale(_s, &block)                      = block.call
    def rotate(_angle, _cx = 0, _cy = 0, &block) = block.call

    def replay(target, alpha_mul:)
      @commands.each do |cmd|
        case cmd.kind
        when :triangle
          x1, y1, c1, x2, y2, c2, x3, y3, c3, z = cmd.args
          target.draw_triangle(
            x1, y1, fade(c1, alpha_mul),
            x2, y2, fade(c2, alpha_mul),
            x3, y3, fade(c3, alpha_mul),
            z
          )
        when :rect
          x, y, w, h, c, z = cmd.args
          target.draw_rect(x, y, w, h, fade(c, alpha_mul), z)
        when :line
          x1, y1, c1, x2, y2, c2, z = cmd.args
          target.draw_line(x1, y1, fade(c1, alpha_mul), x2, y2, fade(c2, alpha_mul), z)
        when :text
          str, x, y, h, c, ax, ay, z = cmd.args
          target.draw_text(str, x, y, h, fade(c, alpha_mul), ax, ay, z)
        end
      end
    end

    private

    def fade(color, mul)
      r, g, b, a = color
      [r, g, b, (a * mul).clamp(0, 255).to_i]
    end
  end
end
