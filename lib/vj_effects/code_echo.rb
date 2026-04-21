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

    # DSL: visual.rb 本体を画面に映す (Notion 計画 G1)
    def CodeEcho(path: 'visual.rb', x: -15, y: 8, size: 0.4,
                 max_lines: 35, line_height: 0.6,
                 hue0: 120, hue_step: 3, sat: 0.6, val: 1.0, z: 0)
      code = File.read(path) rescue ''
      VjEffects::CodeEcho.build_lines(
        code, x0: x, y0: y, line_height: line_height, max_lines: max_lines,
        hue0: hue0, hue_step: hue_step,
      ).each do |l|
        Text(l[:text],
             x: l[:x], y: l[:y], size: size,
             color: {h: l[:hue], s: sat, v: val, a: l[:alpha]},
             align_y: :top, z: z)
      end
    end
  end
end
