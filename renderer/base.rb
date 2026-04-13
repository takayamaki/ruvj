module VjRenderer
  def self.use(renderer)
    prev = @current
    @current = renderer
    if block_given?
      begin
        yield
      ensure
        @current = prev
      end
    end
  end

  def self.current = @current
end
