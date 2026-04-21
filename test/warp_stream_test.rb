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

  def self.draw_rect(*args)      = DRAW_LOG << DrawCall.new(:rect,     args)
  def self.draw_triangle(*args)  = DRAW_LOG << DrawCall.new(:triangle, args)
  def self.draw_line(*args)      = DRAW_LOG << DrawCall.new(:line,     args)
  def self.translate(x, y)       = yield
  def self.scale(sx, sy = sx)    = yield
end

require_relative '../lib/renderer/base'
require_relative '../native/renderer/gosu'
require_relative '../lib/warp_stream'

class WarpStreamTest < Minitest::Test
  def setup
    Gosu::DRAW_LOG.clear
    VjRenderer.use(GosuRenderer.new)
    srand(42)
  end

  def teardown
    VjRenderer.use(nil)
  end

  def test_step_without_thickness_draws_hairline_with_draw_line
  end

  def test_step_with_positive_thickness_draws_thick_lines_as_triangles
  end
end
