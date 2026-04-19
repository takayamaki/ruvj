module VjEffects
  module CodeEcho
    # 純粋関数: ソースコードから行ごとの描画パラメータを生成する
    def self.build_lines(code, x0:, y0:, line_height:, max_lines: 35,
                         hue0: 120.0, hue_step: 3.0,
                         alpha_step: 6, alpha_min: 60, alpha_max: 255)
      code.lines.first(max_lines).each_with_index.map do |line, i|
        {
          text:  line.chomp,
          x:     x0,
          y:     y0 - i * line_height,
          alpha: [alpha_max - i * alpha_step, alpha_min].max,
          hue:   (hue0 + i * hue_step) % 360,
        }
      end
    end
  end
end
