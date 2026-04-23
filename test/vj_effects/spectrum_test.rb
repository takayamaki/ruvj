require 'minitest/autorun'

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
end

require_relative '../../lib/renderer/base'
require_relative '../../native/renderer/gosu'
require_relative '../../lib/vj_shapes'
require_relative '../../lib/vj_effects/spectrum'

class SpectrumTest < Minitest::Test
  include VjShapes
  include VjEffects::Spectrum

  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
    stub_spectrum([0.5, 1.0, 0.25])
  end

  def teardown
    VjRenderer.use(nil)
  end

  def stub_spectrum(values)
    vj = Object.new
    vj.define_singleton_method(:spectrum) { |_n| values }
    @vj = vj
  end

  def rects
    Gosu::DRAW_LOG.select { |c| c.method == :rect }
  end

  def test_emits_one_rect_per_band
    Spectrum(n: 3, gap: 0)
    assert_equal 3, rects.size
  end

  def test_zero_value_band_is_skipped
    stub_spectrum([0.0, 1.0, 0.0])
    Spectrum(n: 3, gap: 0)
    assert_equal 1, rects.size
  end

  def test_bar_height_scales_with_value_in_pixels
    Spectrum(n: 3, height: 6, gap: 0)
    heights = rects.map { |c| c.args[3] }
    assert_in_delta 0.5  * 6 * UNIT, heights[0], 0.001
    assert_in_delta 1.0  * 6 * UNIT, heights[1], 0.001
    assert_in_delta 0.25 * 6 * UNIT, heights[2], 0.001
  end

  def test_bars_bottom_aligns_to_y_base
    Spectrum(n: 3, y: -8, height: 6, gap: 0)
    # y=-8 はピクセル H/2 - (-8)*UNIT = 360 + 320 = 680
    rects.each do |c|
      top_px, h_px = c.args[1], c.args[3]
      assert_in_delta 680.0, top_px + h_px, 0.001
    end
  end

  def test_bars_are_centered_around_x
    Spectrum(n: 3, x: 0, width: 24, gap: 0)
    # width=24, n=3 → bar_w=8, 中央 bar は x=0 を中心
    mid_bar = rects[1]
    left_px, w_px = mid_bar.args[0], mid_bar.args[2]
    center_px = left_px + w_px / 2.0
    assert_in_delta 640.0, center_px, 0.001
  end

  def test_gap_reduces_bar_width
    Spectrum(n: 3, width: 24, gap: 0.5)
    # bar_w=8, gap=0.5 → 描画幅 = (8 - 0.5) * UNIT = 7.5 * 40 = 300
    assert_in_delta 7.5 * UNIT, rects.first.args[2], 0.001
  end

  def expected_rgb(h, s, v)
    r, g, b, _a = hsv_to_color(h: h, s: s, v: v)
    [r, g, b]
  end

  def test_numeric_hue_applies_same_hue_to_all_bars
    Spectrum(n: 3, gap: 0, hue: 120, sat: 0.8, val: 1.0)
    exp = expected_rgb(120, 0.8, 1.0)
    rects.each do |c|
      color = c.args[4]
      assert_equal exp, [color.red, color.green, color.blue]
    end
  end

  def test_range_hue_distributes_hues_across_bars
    Spectrum(n: 3, gap: 0, hue: 0..360, sat: 0.8, val: 1.0)
    # i/n で割り当て: i=0 → h=0, i=1 → h=120, i=2 → h=240
    colors = rects.map { |c| c.args[4] }
    assert_equal expected_rgb(0,   0.8, 1.0), [colors[0].red, colors[0].green, colors[0].blue]
    assert_equal expected_rgb(120, 0.8, 1.0), [colors[1].red, colors[1].green, colors[1].blue]
    assert_equal expected_rgb(240, 0.8, 1.0), [colors[2].red, colors[2].green, colors[2].blue]
  end

  def test_default_hue_is_full_circle_range
  end
end
