require 'minitest/autorun'

# GosuRenderer が内部で使う Gosu モジュールのフェイク
module Gosu
  class Color
    attr_reader :alpha, :red, :green, :blue
    def initialize(a, r, g, b)
      @alpha, @red, @green, @blue = a, r, g, b
    end
  end

  DrawCall = Struct.new(:method, :args)
  DRAW_LOG = []

  def self.draw_rect(*args)      = DRAW_LOG << DrawCall.new(:rect,     args)
  def self.draw_triangle(*args)  = DRAW_LOG << DrawCall.new(:triangle, args)
  def self.draw_line(*args)      = DRAW_LOG << DrawCall.new(:line,     args)
  def self.translate(x, y)       = yield
  def self.scale(sx, sy = sx)    = yield

  class Font
    attr_reader :height, :options
    def initialize(height, **opts)
      @height = height
      @options = opts
    end

    # ダミー幅: 1文字 = height * 0.6px (Monospaceっぽい比率)
    def text_width(text)
      text.length * @height * 0.6
    end

    def draw_text(text, x, y, z, sx, sy, color)
      DRAW_LOG << DrawCall.new(:text, [text, x, y, z, sx, sy, color, @height])
    end
  end
end

require_relative '../lib/renderer/base'
require_relative '../native/renderer/gosu'
require_relative '../lib/vj_shapes'

class VjPxTest < Minitest::Test
  include VjShapes

  def test_origin_maps_to_screen_center
    assert_equal [640.0, 360.0], vj_px(0, 0)
  end

  def test_right_edge_maps_to_right_of_screen
    assert_equal [1280.0, 360.0], vj_px(16, 0)
  end

  def test_left_edge_maps_to_left_of_screen
    assert_equal [0.0, 360.0], vj_px(-16, 0)
  end

  def test_top_edge_maps_to_top_of_screen
    assert_equal [640.0, 0.0], vj_px(0, 9)
  end

  def test_bottom_edge_maps_to_bottom_of_screen
    assert_equal [640.0, 720.0], vj_px(0, -9)
  end
end

class ShapesTest < Minitest::Test
  include VjShapes

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
  end

  def teardown
    VjRenderer.use(nil)
  end

  # --- Bg ---
  def test_bg_fills_full_screen
    Bg(color: {h: 0, s: 0, v: 0})
    call = Gosu::DRAW_LOG.first
    assert_equal :rect, call.method
    assert_equal 0,    call.args[0]
    assert_equal 0,    call.args[1]
    assert_equal W,    call.args[2]
    assert_equal H,    call.args[3]
  end

  def test_bg_uses_hsv_color
    Bg(color: {h: 0, s: 1, v: 1})
    color = Gosu::DRAW_LOG.first.args[4]
    assert_operator color.red, :>, 200
  end

  # --- Circle ---
  def test_circle_at_origin_draws_at_screen_center
    Circle(r: 1, color: {h: 0, s: 1, v: 1})
    cx, cy = Gosu::DRAW_LOG.first.args[0], Gosu::DRAW_LOG.first.args[1]
    assert_in_delta 640.0, cx, 0.001
    assert_in_delta 360.0, cy, 0.001
  end

  def test_circle_at_offset_position_draws_at_correct_pixel
    Circle(x: 1, y: 1, r: 1, color: {h: 0, s: 1, v: 1})
    cx, cy = Gosu::DRAW_LOG.first.args[0], Gosu::DRAW_LOG.first.args[1]
    assert_in_delta 680.0, cx, 0.001  # 640 + 1*40
    assert_in_delta 320.0, cy, 0.001  # 360 - 1*40
  end

  # --- Rect ---
  def test_rect_at_origin_centers_on_screen
    Rect(w: 2, h: 1, color: {h: 0, s: 1, v: 1})
    call = Gosu::DRAW_LOG.first
    assert_in_delta 640.0 - 1 * UNIT, call.args[0], 0.001
    assert_in_delta 360.0 - 0.5 * UNIT, call.args[1], 0.001
  end

  def test_rect_size_is_scaled_by_unit
    Rect(w: 4, h: 2, color: {h: 0, s: 1, v: 1})
    call = Gosu::DRAW_LOG.first
    assert_in_delta 4 * UNIT, call.args[2], 0.001
    assert_in_delta 2 * UNIT, call.args[3], 0.001
  end

  # --- Triangle ---
  def test_triangle_at_origin_draws_without_error
    Triangle(size: 1, color: {h: 0, s: 1, v: 1})
    refute_empty Gosu::DRAW_LOG
  end

  # --- Line ---
  def test_line_endpoints_are_converted_to_pixels
    Line(x1: -1, y1: 0, x2: 1, y2: 0, color: {h: 0, s: 1, v: 1})
    call = Gosu::DRAW_LOG.first
    assert_in_delta 640.0 - UNIT, call.args[0], 0.001  # x1
    assert_in_delta 360.0,        call.args[1], 0.001  # y1
    assert_in_delta 640.0 + UNIT, call.args[3], 0.001  # x2
    assert_in_delta 360.0,        call.args[4], 0.001  # y2
  end

  def test_line_with_bold_zero_uses_draw_line
    Line(x1: -1, y1: 0, x2: 1, y2: 0, color: {h: 0, s: 1, v: 1}, bold: 0)
    assert_equal [:line], Gosu::DRAW_LOG.map(&:method)
  end

  def test_line_with_positive_bold_draws_quad_as_two_triangles
    Line(x1: -1, y1: 0, x2: 1, y2: 0, color: {h: 0, s: 1, v: 1}, bold: 50)
    assert_equal [:triangle, :triangle], Gosu::DRAW_LOG.map(&:method)
  end

  # 水平線 (y 一定) に bold=100 (= 1 VJユニット幅) を与えると、y 方向に ±UNIT/2 の幅が出るはず
  def test_line_bold_spreads_perpendicular_to_line_direction
    Line(x1: -2, y1: 0, x2: 2, y2: 0, color: {h: 0, s: 1, v: 1}, bold: 100)
    tris = Gosu::DRAW_LOG
    ys = tris.flat_map { |c| [c.args[1], c.args[4], c.args[7]] }
    assert_in_delta 360.0 - UNIT / 2.0, ys.min, 0.001
    assert_in_delta 360.0 + UNIT / 2.0, ys.max, 0.001
  end

  # --- Lissajous ---
  # Line の x1/x2 は vj_px 通過後のピクセル座標。画面中心 640.0 からの最大偏差が rx*UNIT に収まることを見る
  def lissajous_x_pixels
    Gosu::DRAW_LOG.flat_map { |c| [c.args[0], c.args[3]] }
  end

  def lissajous_y_pixels
    Gosu::DRAW_LOG.flat_map { |c| [c.args[1], c.args[4]] }
  end

  def test_lissajous_x_amplitude_is_bounded_by_rx
    Lissajous(a: 3, b: 2, rx: 4, ry: 1, color: {h: 0, s: 1, v: 1})
    xs = lissajous_x_pixels
    max_dx = xs.map { |x| (x - 640.0).abs }.max
    assert_in_delta 4 * UNIT, max_dx, 0.5
  end

  def test_lissajous_y_amplitude_is_bounded_by_ry
    Lissajous(a: 3, b: 2, rx: 1, ry: 4, color: {h: 0, s: 1, v: 1})
    ys = lissajous_y_pixels
    max_dy = ys.map { |y| (y - 360.0).abs }.max
    assert_in_delta 4 * UNIT, max_dy, 0.5
  end

  def test_lissajous_with_equal_rx_ry_has_equal_x_and_y_amplitude
    Lissajous(a: 3, b: 2, rx: 3, ry: 3, color: {h: 0, s: 1, v: 1})
    max_dx = lissajous_x_pixels.map { |x| (x - 640.0).abs }.max
    max_dy = lissajous_y_pixels.map { |y| (y - 360.0).abs }.max
    assert_in_delta max_dx, max_dy, 0.5
  end

  def test_lissajous_bold_passes_through_to_line
    Lissajous(a: 3, b: 2, rx: 4, ry: 4, steps: 16, color: {h: 0, s: 1, v: 1}, bold: 30)
    methods = Gosu::DRAW_LOG.map(&:method).uniq
    assert_equal [:triangle], methods
  end
end

class TextTest < Minitest::Test
  include VjShapes

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
  end

  def teardown
    VjRenderer.use(nil)
  end

  # --- 典型: 数値HUD的な使い方 ---
  def test_text_at_origin_draws_near_screen_center
    Text('hi', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1})
    call = Gosu::DRAW_LOG.find { |c| c.method == :text }
    refute_nil call, 'Text が draw_text を呼んでいない'
    text, x, y, _z, _sx, _sy, _color, height = call.args
    assert_equal 'hi', text
    # align_x: :left (default) なので x はそのまま vj_px(0,0)[0] = 640.0
    assert_in_delta 640.0, x, 0.001
    # align_y: :middle (default) なので y は vj_px(0,0)[1] - height/2 = 360 - 40/2 = 340
    assert_in_delta 340.0, y, 0.001
    assert_equal UNIT, height
  end

  # --- 位置 ---
  def test_text_xy_is_converted_to_pixels_via_vj_px
    Text('x', x: 2, y: 1, size: 1, color: {h: 0, s: 1, v: 1})
    _, x, y, = Gosu::DRAW_LOG.find { |c| c.method == :text }.args
    # vj_px(2, 1) = [720, 320], align_y :middle で -20
    assert_in_delta 720.0, x, 0.001
    assert_in_delta 300.0, y, 0.001
  end

  # --- サイズ ---
  def test_size_is_scaled_by_unit_to_font_height
    Text('s', x: 0, y: 0, size: 2, color: {h: 0, s: 1, v: 1})
    height = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[7]
    assert_in_delta UNIT * 2, height, 0.001
  end

  # --- 色 ---
  def test_color_is_converted_from_hsv
    Text('c', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1})  # HSV赤
    color = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[6]
    assert_operator color.red,   :>, 200
    assert_operator color.green, :<, 10
    assert_operator color.blue,  :<, 10
  end

  # --- 水平アライン ---
  def test_align_x_left_is_default_and_anchor_is_x
    Text('abc', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1})
    x = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[1]
    # 左揃え: vj_px(0,0)[0] そのまま
    assert_in_delta 640.0, x, 0.001
  end

  def test_align_x_center_shifts_left_by_half_text_width
    Text('abc', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, align_x: :center)
    x = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[1]
    # text_width = 3文字 * 40 * 0.6 = 72, 中心揃えで -36
    assert_in_delta 640.0 - 36.0, x, 0.001
  end

  def test_align_x_right_shifts_left_by_full_text_width
    Text('abc', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, align_x: :right)
    x = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[1]
    assert_in_delta 640.0 - 72.0, x, 0.001
  end

  # --- 垂直アライン ---
  def test_align_y_middle_is_default_and_shifts_up_by_half_height
    Text('m', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1})
    y = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[2]
    # vj_px(0,0)[1] = 360, middle で height/2 = 20 上 → 340
    assert_in_delta 340.0, y, 0.001
  end

  def test_align_y_top_anchor_is_y
    Text('t', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, align_y: :top)
    y = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[2]
    # 上端揃え: vj_px(0,0)[1] = 360 そのまま
    assert_in_delta 360.0, y, 0.001
  end

  def test_align_y_bottom_shifts_up_by_full_height
    Text('b', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, align_y: :bottom)
    y = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[2]
    # 下端揃え: 360 - height(40) = 320
    assert_in_delta 320.0, y, 0.001
  end

  # --- その他 ---
  def test_z_is_passed_through
    Text('z', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, z: 7)
    z = Gosu::DRAW_LOG.find { |c| c.method == :text }.args[3]
    assert_equal 7, z
  end

  def test_empty_string_does_not_raise
    Text('', x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1})
    refute_nil Gosu::DRAW_LOG.find { |c| c.method == :text }
  end

  # --- 複数行 ---
  def test_multiline_splits_at_newline_and_draws_per_line
    Text("foo\nbar\nbaz", x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1})
    texts = Gosu::DRAW_LOG.select { |c| c.method == :text }.map { |c| c.args[0] }
    assert_equal %w[foo bar baz], texts
  end

  # align_y: :top で 1行目 py、2行目 py + height、3行目 py + 2*height となるはず
  def test_multiline_each_line_is_offset_by_font_height
    Text("a\nb\nc", x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, align_y: :top)
    ys = Gosu::DRAW_LOG.select { |c| c.method == :text }.map { |c| c.args[2] }
    assert_in_delta 360.0,            ys[0], 0.001
    assert_in_delta 360.0 + UNIT,     ys[1], 0.001
    assert_in_delta 360.0 + 2 * UNIT, ys[2], 0.001
  end

  # 3行・middle の場合、真ん中の行(2行目)の中心が py の位置 (=360) に来るはず
  def test_multiline_align_y_middle_centers_whole_block_vertically
    Text("a\nb\nc", x: 0, y: 0, size: 1, color: {h: 0, s: 1, v: 1}, align_y: :middle)
    ys = Gosu::DRAW_LOG.select { |c| c.method == :text }.map { |c| c.args[2] }
    # ブロック全高 = 3 * UNIT、上端 = py - 1.5*UNIT、各行 ベースライン y は上端 + i*UNIT
    assert_in_delta 360.0 - 1.5 * UNIT, ys[0], 0.001
    assert_in_delta 360.0 - 0.5 * UNIT, ys[1], 0.001
    assert_in_delta 360.0 + 0.5 * UNIT, ys[2], 0.001
  end
end

class HsvToColorTest < Minitest::Test
  include VjShapes

  def test_red_hsv_produces_high_red_component
    r, g, b, _a = hsv_to_color({h: 0, s: 1, v: 1})
    assert_operator r, :>, 200
    assert_operator g, :<, 10
    assert_operator b, :<, 10
  end

  def test_green_hsv_produces_high_green_component
    _r, g, b, _a = hsv_to_color({h: 120, s: 1, v: 1})
    assert_operator g, :>, 200
    assert_operator b, :<, 10
  end

  def test_blue_hsv_produces_high_blue_component
    r, _g, b, _a = hsv_to_color({h: 240, s: 1, v: 1})
    assert_operator b, :>, 200
    assert_operator r, :<, 10
  end

  def test_alpha_defaults_to_255_when_a_key_absent
    _r, _g, _b, a = hsv_to_color({h: 0, s: 1, v: 1})
    assert_equal 255, a
  end

  def test_alpha_is_read_from_a_key
    _r, _g, _b, a = hsv_to_color({h: 0, s: 1, v: 1, a: 128})
    assert_equal 128, a
  end

  # h 欠落時は h=0 (赤) で補完されるはず
  def test_h_defaults_to_0_when_absent
    r, g, b, _a = hsv_to_color({s: 1, v: 1})
    assert_operator r, :>, 200
    assert_operator g, :<, 10
    assert_operator b, :<, 10
  end

  # s 欠落時は s=1 (彩度最大) で補完されるはず。h=120 (緑) で検証
  def test_s_defaults_to_1_when_absent
    r, g, b, _a = hsv_to_color({h: 120, v: 1})
    assert_operator g, :>, 200
    assert_operator r, :<, 10
    assert_operator b, :<, 10
  end

  # v 欠落時は v=1 (明度最大) で補完されるはず
  def test_v_defaults_to_1_when_absent
    r, _g, _b, _a = hsv_to_color({h: 0, s: 1})
    assert_operator r, :>, 200
  end

  def test_hue_wraps_around_360
    r1, g1, b1, _ = hsv_to_color({h: 0,   s: 1, v: 1})
    r2, g2, b2, _ = hsv_to_color({h: 360, s: 1, v: 1})
    assert_equal r1, r2
    assert_equal g1, g2
    assert_equal b1, b2
  end
end

class RingTest < Minitest::Test
  include VjShapes

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
  end

  def teardown
    VjRenderer.use(nil)
  end

  # --- Ring: 基本動作 ---
  def test_ring_draws_line_segments
    skip
  end

  def test_ring_segment_count_matches_steps
    skip
  end

  def test_ring_at_origin_draws_around_screen_center
    skip
  end

  def test_ring_at_offset_position_draws_around_correct_pixel
    skip
  end

  # --- Ring: steps パラメータ ---
  def test_ring_custom_steps_draws_correct_count
    skip
  end

  # --- Ring: 半径 ---
  def test_ring_radius_scales_with_unit
    skip
  end
end

class TunnelTest < Minitest::Test
  include VjShapes

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
  end

  def teardown
    VjRenderer.use(nil)
  end

  # --- Tunnel: 基本動作 ---
  def test_tunnel_draws_multiple_rings
    skip
  end

  def test_tunnel_ring_count_matches_n
    skip
  end

  # --- Tunnel: alpha（奥→手前のグラデーション）---
  def test_tunnel_innermost_ring_is_transparent
    skip
  end

  def test_tunnel_outermost_ring_is_opaque
    skip
  end

  # --- Tunnel: offset ---
  def test_tunnel_offset_shifts_ring_phases
    skip
  end

  # --- Tunnel: r_max ---
  def test_tunnel_r_max_controls_outermost_radius
    skip
  end
end

class PolarTest < Minitest::Test
  include VjShapes

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
  end

  def teardown
    VjRenderer.use(nil)
  end

  # --- 基本軸 ---
  def test_angle_0_points_right
    assert_in_delta  1.0, polar(1, 0)[:x], 1e-10
    assert_in_delta  0.0, polar(1, 0)[:y], 1e-10
  end

  def test_angle_half_pi_points_up
    assert_in_delta  0.0, polar(1, Math::PI / 2)[:x], 1e-10
    assert_in_delta  1.0, polar(1, Math::PI / 2)[:y], 1e-10
  end

  # --- 半径 ---
  def test_radius_scales_output
    assert_in_delta  3.0, polar(3, 0)[:x], 1e-10
    assert_in_delta  0.0, polar(3, 0)[:y], 1e-10
  end

  # --- 任意角度 ---
  def test_arbitrary_angle_matches_trig
    r, t = 2.5, 1.2
    p = polar(r, t)
    assert_in_delta r * Math.cos(t), p[:x], 1e-10
    assert_in_delta r * Math.sin(t), p[:y], 1e-10
  end

  # --- ** 展開 ---
  def test_can_splat_into_keyword_args
    Circle(**polar(2, 0), r: 1, color: {h: 0, s: 1, v: 1})
    cx = Gosu::DRAW_LOG.first.args[0]
    assert_in_delta 640.0 + 2 * UNIT, cx, 0.001
  end
end
