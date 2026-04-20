require 'osc-ruby'

class OscReceiver
  PORT = 57120

  def initialize
    @values = {}
    @mutex  = Mutex.new
    start_server
  end

  def [](address)
    @mutex.synchronize { @values[address] || 0.0 }
  end

  private

  def start_server
    server = OSC::Server.new(PORT)
    server.add_method(/.*/) do |msg|
      raw = msg.to_a.first.to_f
      # MIDI CC (0〜127) は 0.0〜1.0 に正規化、すでに 0.0〜1.0 ならそのまま
      val = raw > 1.0 ? (raw / 127.0) : raw
      @mutex.synchronize { @values[msg.address] = val.clamp(0.0, 1.0) }
    end
    Thread.new { server.run }
    $stderr.puts "OSC listening on UDP #{PORT}"
  rescue => e
    $stderr.puts "OSC server error: #{e.message}"
  end
end
