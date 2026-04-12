require 'minitest/autorun'

module Gosu
  class Color
    attr_reader :alpha, :red, :green, :blue
    def initialize(a, r, g, b)
      @alpha, @red, @green, @blue = a, r, g, b
    end
  end

  DrawCall = Struct.new(:method, :args)
  DRAW_LOG = []

  def self.draw_rect(*args)   = DRAW_LOG << DrawCall.new(:rect,     args)
  def self.draw_triangle(*args) = DRAW_LOG << DrawCall.new(:triangle, args)
  def self.draw_line(*args)   = DRAW_LOG << DrawCall.new(:line,     args)
end

require_relative '../vj_shapes'

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
    # 中心点は全三角形の最初の頂点（cx, cy）が画面中央
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
    # draw_rect(x, y, w, h, color, z) — 左上座標は中央からw/2,h/2ずれる
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

class HsvArrayToColorTest < Minitest::Test
  include VjShapes

  def test_red_hsv_produces_high_red_component
    c = hsv_to_gosu([0, 1, 1])
    assert_operator c.red,   :>, 200
    assert_operator c.green, :<, 10
    assert_operator c.blue,  :<, 10
  end

  def test_green_hsv_produces_high_green_component
    c = hsv_to_gosu([120, 1, 1])
    assert_operator c.green, :>, 200
    assert_operator c.red,   :<, 10
    assert_operator c.blue,  :<, 10
  end

  def test_blue_hsv_produces_high_blue_component
    c = hsv_to_gosu([240, 1, 1])
    assert_operator c.blue,  :>, 200
    assert_operator c.red,   :<, 10
    assert_operator c.green, :<, 10
  end

  def test_alpha_defaults_to_255
    c = hsv_to_gosu([0, 1, 1])
    assert_equal 255, c.alpha
  end

  def test_alpha_can_be_specified_as_fourth_element
    c = hsv_to_gosu([0, 1, 1, 128])
    assert_equal 128, c.alpha
  end

  def test_hue_wraps_around_360
    c1 = hsv_to_gosu([0,   1, 1])
    c2 = hsv_to_gosu([360, 1, 1])
    assert_equal c1.red,   c2.red
    assert_equal c1.green, c2.green
    assert_equal c1.blue,  c2.blue
  end
end

class PolarTest < Minitest::Test
  include VjShapes

  # --- 基本軸 ---
  def test_angle_0_points_right
    x, y = polar(1, 0)
    assert_in_delta  1.0, x, 1e-10
    assert_in_delta  0.0, y, 1e-10
  end

  def test_angle_half_pi_points_up
    x, y = polar(1, Math::PI / 2)
    assert_in_delta  0.0, x, 1e-10
    assert_in_delta  1.0, y, 1e-10
  end

  # --- 半径 ---
  def test_radius_scales_output
    x, y = polar(3, 0)
    assert_in_delta  3.0, x, 1e-10
    assert_in_delta  0.0, y, 1e-10
  end

  # --- 任意角度 ---
  def test_arbitrary_angle_matches_trig
    r, t = 2.5, 1.2
    x, y = polar(r, t)
    assert_in_delta r * Math.cos(t), x, 1e-10
    assert_in_delta r * Math.sin(t), y, 1e-10
  end
end
