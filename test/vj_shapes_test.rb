require 'minitest/autorun'

module Gosu
  class Color
    attr_reader :alpha, :red, :green, :blue
    def initialize(a, r, g, b)
      @alpha, @red, @green, @blue = a, r, g, b
    end
  end
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
