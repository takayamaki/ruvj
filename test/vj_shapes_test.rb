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

  def test_s_defaults_to_1_when_absent
  end

  def test_v_defaults_to_1_when_absent
  end

  def test_hue_wraps_around_360
    r1, g1, b1, _ = hsv_to_color({h: 0,   s: 1, v: 1})
    r2, g2, b2, _ = hsv_to_color({h: 360, s: 1, v: 1})
    assert_equal r1, r2
    assert_equal g1, g2
    assert_equal b1, b2
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
