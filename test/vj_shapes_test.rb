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
    Bg(color: [0, 0, 0])
    call = Gosu::DRAW_LOG.first
    assert_equal :rect, call.method
    assert_equal 0,    call.args[0]
    assert_equal 0,    call.args[1]
    assert_equal W,    call.args[2]
    assert_equal H,    call.args[3]
  end

  def test_bg_uses_hsv_color
    Bg(color: [0, 1, 1])
    color = Gosu::DRAW_LOG.first.args[4]
    assert_operator color.red, :>, 200
  end

  # --- Circle ---
  def test_circle_at_origin_draws_at_screen_center
    Circle(r: 1, color: [0, 1, 1])
    cx, cy = Gosu::DRAW_LOG.first.args[0], Gosu::DRAW_LOG.first.args[1]
    assert_in_delta 640.0, cx, 0.001
    assert_in_delta 360.0, cy, 0.001
  end

  def test_circle_at_offset_position_draws_at_correct_pixel
    Circle(x: 1, y: 1, r: 1, color: [0, 1, 1])
    cx, cy = Gosu::DRAW_LOG.first.args[0], Gosu::DRAW_LOG.first.args[1]
    assert_in_delta 680.0, cx, 0.001  # 640 + 1*40
    assert_in_delta 320.0, cy, 0.001  # 360 - 1*40
  end

  # --- Rect ---
  def test_rect_at_origin_centers_on_screen
    Rect(w: 2, h: 1, color: [0, 1, 1])
    call = Gosu::DRAW_LOG.first
    assert_in_delta 640.0 - 1 * UNIT, call.args[0], 0.001
    assert_in_delta 360.0 - 0.5 * UNIT, call.args[1], 0.001
  end

  def test_rect_size_is_scaled_by_unit
    Rect(w: 4, h: 2, color: [0, 1, 1])
    call = Gosu::DRAW_LOG.first
    assert_in_delta 4 * UNIT, call.args[2], 0.001
    assert_in_delta 2 * UNIT, call.args[3], 0.001
  end

  # --- Triangle ---
  def test_triangle_at_origin_draws_without_error
    Triangle(size: 1, color: [0, 1, 1])
    refute_empty Gosu::DRAW_LOG
  end

  # --- Line ---
  def test_line_endpoints_are_converted_to_pixels
    Line(x1: -1, y1: 0, x2: 1, y2: 0, color: [0, 1, 1])
    call = Gosu::DRAW_LOG.first
    assert_in_delta 640.0 - UNIT, call.args[0], 0.001  # x1
    assert_in_delta 360.0,        call.args[1], 0.001  # y1
    assert_in_delta 640.0 + UNIT, call.args[3], 0.001  # x2
    assert_in_delta 360.0,        call.args[4], 0.001  # y2
  end
end

class HsvToColorTest < Minitest::Test
  include VjShapes

  def test_red_hsv_produces_high_red_component
    r, g, b, _a = hsv_to_color([0, 1, 1])
    assert_operator r, :>, 200
    assert_operator g, :<, 10
    assert_operator b, :<, 10
  end

  def test_green_hsv_produces_high_green_component
    _r, g, b, _a = hsv_to_color([120, 1, 1])
    assert_operator g, :>, 200
    assert_operator b, :<, 10
  end

  def test_blue_hsv_produces_high_blue_component
    r, _g, b, _a = hsv_to_color([240, 1, 1])
    assert_operator b, :>, 200
    assert_operator r, :<, 10
  end

  def test_alpha_defaults_to_255
    _r, _g, _b, a = hsv_to_color([0, 1, 1])
    assert_equal 255, a
  end

  def test_alpha_can_be_specified_as_fourth_element
    _r, _g, _b, a = hsv_to_color([0, 1, 1, 128])
    assert_equal 128, a
  end

  def test_hue_wraps_around_360
    r1, g1, b1, _ = hsv_to_color([0,   1, 1])
    r2, g2, b2, _ = hsv_to_color([360, 1, 1])
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
    Circle(**polar(2, 0), r: 1, color: [0, 1, 1])
    cx = Gosu::DRAW_LOG.first.args[0]
    assert_in_delta 640.0 + 2 * UNIT, cx, 0.001
  end
end
