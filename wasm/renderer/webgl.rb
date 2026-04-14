require_relative '../../lib/renderer/base'

class WebGLRenderer
  VERTEX_FLOATS = 6  # x, y, r, g, b, a per vertex

  VERT_SRC = <<~GLSL
    #version 300 es
    in vec2 a_pos;
    in vec4 a_color;
    out vec4 v_color;
    uniform vec2 u_resolution;
    void main() {
      vec2 clip = (a_pos / u_resolution) * 2.0 - 1.0;
      gl_Position = vec4(clip.x, -clip.y, 0, 1);
      v_color = a_color;
    }
  GLSL

  FRAG_SRC = <<~GLSL
    #version 300 es
    precision mediump float;
    in vec4 v_color;
    out vec4 out_color;
    void main() { out_color = v_color; }
  GLSL

  def initialize(canvas_id: 'canvas')
    null_js = JS.eval("null")
    doc = JS.global[:document]
    @canvas = doc.call(:getElementById, canvas_id)
    clog "canvas: #{@canvas[:width]}x#{@canvas[:height]}"

    @gl = @canvas.call(:getContext, 'webgl2')
    if @gl == null_js
      clog "WebGL2 not available, trying webgl..."
      @gl = @canvas.call(:getContext, 'webgl')
      raise 'WebGL not available' if @gl == null_js
      clog "WebGL1 fallback active (some features may differ)"
    else
      clog "WebGL2 context OK"
    end

    setup_program
    setup_buffer
    @vertices = []
    @pending_lines = []
    @transform_stack = []
    @current_transform = identity_matrix
    @first_flush_done = false
  end

  # --- Transform ---

  def translate(x, y)
    push_transform(translation_matrix(x, y))
    yield
  ensure
    pop_transform
  end

  def scale(s)
    push_transform(scale_matrix(s))
    yield
  ensure
    pop_transform
  end

  # --- Draw primitives ---

  def draw_triangle(x1, y1, c1, x2, y2, c2, x3, y3, c3, z = 0)
    add_vertex(x1, y1, c1)
    add_vertex(x2, y2, c2)
    add_vertex(x3, y3, c3)
  end

  def draw_rect(x, y, w, h, color, z = 0)
    draw_triangle(x,     y,     color, x + w, y,     color, x + w, y + h, color)
    draw_triangle(x,     y,     color, x + w, y + h, color, x,     y + h, color)
  end

  def draw_line(x1, y1, c1, x2, y2, c2, z = 0)
    @pending_lines << [x1, y1, c1, x2, y2, c2]
  end

  def begin_frame
    @vertices.clear
    @pending_lines.clear
    w = @canvas[:width].to_i
    h = @canvas[:height].to_i
    @gl.call(:viewport, 0, 0, w, h)
    @gl.call(:clear, @gl[:COLOR_BUFFER_BIT])
  end

  def flush!
    draw_triangles_batch
    draw_lines_batch

    unless @first_flush_done
      err = @gl.call(:getError).to_i
      clog "first flush: tri_verts=#{@vertices.size} lines=#{@pending_lines.size} gl_error=#{err}"
      @first_flush_done = true
    end
  end

  private

  def clog(msg) = JS.global[:console].call(:log,  "[WebGL] #{msg}")
  def cerr(msg) = JS.global[:console].call(:error, "[WebGL] #{msg}")

  # --- Transform helpers ---

  def identity_matrix              = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
  def translation_matrix(x, y)    = [1.0, 0.0, x.to_f, 0.0, 1.0, y.to_f]
  def scale_matrix(s)             = [s.to_f, 0.0, 0.0, 0.0, s.to_f, 0.0]

  def push_transform(m)
    @transform_stack.push(@current_transform)
    @current_transform = compose(@current_transform, m)
  end

  def pop_transform
    @current_transform = @transform_stack.pop
  end

  # 2D affine [a, b, tx, c, d, ty] (row-major)
  def compose(a, b)
    [
      a[0]*b[0] + a[1]*b[3],  a[0]*b[1] + a[1]*b[4],  a[0]*b[2] + a[1]*b[5] + a[2],
      a[3]*b[0] + a[4]*b[3],  a[3]*b[1] + a[4]*b[4],  a[3]*b[2] + a[4]*b[5] + a[5]
    ]
  end

  def transform_point(x, y)
    m = @current_transform
    [m[0]*x + m[1]*y + m[2], m[3]*x + m[4]*y + m[5]]
  end

  # --- Vertex buffering ---

  def add_vertex(x, y, color)
    tx, ty = transform_point(x, y)
    r, g, b, a = color
    @vertices.push(tx, ty, r / 255.0, g / 255.0, b / 255.0, a / 255.0)
  end

  # --- GL setup ---

  def setup_program
    vert = compile_shader(@gl[:VERTEX_SHADER],   VERT_SRC)
    frag = compile_shader(@gl[:FRAGMENT_SHADER], FRAG_SRC)

    @program = @gl.call(:createProgram)
    @gl.call(:attachShader, @program, vert)
    @gl.call(:attachShader, @program, frag)
    @gl.call(:linkProgram, @program)

    linked = @gl.call(:getProgramParameter, @program, @gl[:LINK_STATUS])
    unless linked.to_s == 'true'
      log_str = @gl.call(:getProgramInfoLog, @program).to_s
      cerr "program link failed: #{log_str}"
    end
    clog "program linked OK"

    @gl.call(:useProgram, @program)

    @loc_pos   = @gl.call(:getAttribLocation,  @program, 'a_pos').to_i
    @loc_color = @gl.call(:getAttribLocation,  @program, 'a_color').to_i
    @loc_res   = @gl.call(:getUniformLocation, @program, 'u_resolution')
    clog "attrib locations: a_pos=#{@loc_pos} a_color=#{@loc_color}"
  end

  def compile_shader(type, src)
    sh = @gl.call(:createShader, type)
    @gl.call(:shaderSource, sh, src)
    @gl.call(:compileShader, sh)
    ok = @gl.call(:getShaderParameter, sh, @gl[:COMPILE_STATUS])
    unless ok.to_s == 'true'
      log_str = @gl.call(:getShaderInfoLog, sh).to_s
      cerr "shader compile failed: #{log_str}"
    end
    sh
  end

  def setup_buffer
    @vbo = @gl.call(:createBuffer)
    @gl.call(:bindBuffer, @gl[:ARRAY_BUFFER], @vbo)
    stride = VERTEX_FLOATS * 4
    @gl.call(:enableVertexAttribArray, @loc_pos)
    @gl.call(:enableVertexAttribArray, @loc_color)
    @gl.call(:vertexAttribPointer, @loc_pos,   2, @gl[:FLOAT], false, stride, 0)
    @gl.call(:vertexAttribPointer, @loc_color, 4, @gl[:FLOAT], false, stride, 2 * 4)
    clog "VBO setup OK (stride=#{stride})"
  end

  # --- Batch draw ---

  def draw_triangles_batch
    return if @vertices.empty?
    w = @canvas[:width].to_f
    h = @canvas[:height].to_f
    @gl.call(:uniform2f, @loc_res, w, h)

    typed = JS.global[:Float32Array].new(@vertices.size)
    @vertices.each_with_index { |v, i| typed[i] = v }
    @gl.call(:bufferData, @gl[:ARRAY_BUFFER], typed, @gl[:STREAM_DRAW])
    count = @vertices.size / VERTEX_FLOATS
    @gl.call(:drawArrays, @gl[:TRIANGLES], 0, count)
  end

  def draw_lines_batch
    return if @pending_lines.empty?
    line_verts = []
    @pending_lines.each do |x1, y1, c1, x2, y2, c2|
      tx1, ty1 = transform_point(x1, y1)
      tx2, ty2 = transform_point(x2, y2)
      r1, g1, b1, a1 = c1; r2, g2, b2, a2 = c2
      line_verts.push(tx1, ty1, r1/255.0, g1/255.0, b1/255.0, a1/255.0)
      line_verts.push(tx2, ty2, r2/255.0, g2/255.0, b2/255.0, a2/255.0)
    end

    w = @canvas[:width].to_f; h = @canvas[:height].to_f
    @gl.call(:uniform2f, @loc_res, w, h)
    typed = JS.global[:Float32Array].new(line_verts.size)
    line_verts.each_with_index { |v, i| typed[i] = v }
    @gl.call(:bufferData, @gl[:ARRAY_BUFFER], typed, @gl[:STREAM_DRAW])
    @gl.call(:drawArrays, @gl[:LINES], 0, line_verts.size / VERTEX_FLOATS)
  end
end
