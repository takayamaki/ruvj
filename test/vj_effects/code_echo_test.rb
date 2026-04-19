require 'minitest/autorun'
require 'tempfile'

module Gosu
  class Color
    attr_reader :alpha, :red, :green, :blue
    def initialize(a, r, g, b)
      @alpha, @red, @green, @blue = a, r, g, b
    end
  end

  DrawCall = Struct.new(:method, :args)
  DRAW_LOG = [] unless defined?(DRAW_LOG)

  def self.draw_rect(*args)     = DRAW_LOG << DrawCall.new(:rect,     args)
  def self.draw_triangle(*args) = DRAW_LOG << DrawCall.new(:triangle, args)
  def self.draw_line(*args)     = DRAW_LOG << DrawCall.new(:line,     args)
  def self.translate(x, y)      = yield
  def self.scale(sx, sy = sx)   = yield

  class Font
    attr_reader :height
    def initialize(height, **_opts)
      @height = height
    end

    def text_width(text)
      text.length * @height * 0.6
    end

    def draw_text(text, x, y, z, sx, sy, color)
      DRAW_LOG << DrawCall.new(:text, [text, x, y, z, sx, sy, color, @height])
    end
  end unless defined?(Font)
end

require_relative '../../lib/renderer/base'
require_relative '../../native/renderer/gosu'
require_relative '../../lib/vj_shapes'
require_relative '../../lib/vj_effects/code_echo'

# --- 純粋関数 build_lines のテスト ---
class CodeEchoBuildLinesTest < Minitest::Test
  # 典型: 複数行コードを渡して行ごとのレイアウト情報が返る
  def test_returns_one_entry_per_line
    skip 'pending'
  end

  # 各要素の text は chomp 済み
  def test_text_has_trailing_newline_stripped
    skip 'pending'
  end

  # x0 がそのまま各行 x に入る
  def test_x_is_constant_x0
    skip 'pending'
  end

  # y は行ごとに line_height ずつ下方向（y値は減）
  def test_y_decreases_by_line_height_per_row
    skip 'pending'
  end

  # alpha は行ごとに alpha_step ずつ減衰
  def test_alpha_decreases_by_alpha_step_per_row
    skip 'pending'
  end

  # alpha は alpha_min でクランプされる
  def test_alpha_is_clamped_at_alpha_min
    skip 'pending'
  end

  # hue は行ごとに hue_step ずつ増える
  def test_hue_increases_by_hue_step_per_row
    skip 'pending'
  end

  # hue は 360 で wrap する
  def test_hue_wraps_at_360
    skip 'pending'
  end

  # max_lines を超えた行はカット
  def test_lines_beyond_max_lines_are_dropped
    skip 'pending'
  end

  # 空文字列なら空配列
  def test_empty_code_returns_empty_array
    skip 'pending'
  end
end

# --- DSL CodeEcho の統合テスト ---
class CodeEchoDslTest < Minitest::Test
  include VjShapes
  include VjEffects::CodeEcho

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
  end

  def teardown
    VjRenderer.use(nil)
  end

  # 典型: path のファイル内容が行ごとに draw_text される
  def test_draws_one_text_call_per_line_in_file
    skip 'pending'
  end

  # File.read が失敗（存在しないパス）しても例外にならない
  def test_missing_path_does_not_raise
    skip 'pending'
  end
end
