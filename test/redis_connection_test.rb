# frozen_string_literal: true
require "test_helper"

require 'timeout'
require 'socket'

class RedisConnectionTest < Minitest::Test
  class RedisServer
    TimeoutError = Class.new(::Timeout::Error)
    class BufferedIO
      
      def initialize(io, timeout: 5)
        @io = io
        @buffer = String.new(capacity: 8_196, encoding: Encoding::BINARY)
        @timeout = timeout
      end

      def read_line(terminator: "\r\n")
        until index = @buffer.index(terminator)
          fill_buffer
        end
        line = @buffer.slice!(0, index)
        @buffer.slice!(0, terminator.bytesize)
        line
      end

      def read_bytes(bytes, terminator: "\r\n")
        full_bytes = bytes
        full_bytes += terminator.bytesize if terminator
        while @buffer.bytesize < full_bytes
          fill_buffer
        end
        data = @buffer.slice!(0, bytes)
        @buffer.slice!(0, terminator.bytesize) if terminator
        data
      end

      private

      def fill_buffer
        loop do
          case rv = @io.read_nonblock(8_196, @buffer, exception: false)
          when :wait_readable
            @io.wait_readable(@timeout) or raise TimeoutError
          when :wait_writable
            @io.wait_writeable(@timeout) or raise TimeoutError
          when String
            return
          when nil
            raise 'EOF' # EOF
          end
        end
      end
    end

    def initialize(host: 'localhost', port: 6379)
      @host = host
      @port = port
      @socket = nil
      @timeout = 5
    end

    def call(*args)
      
    end

    def connect
      @socket = TCPSocket.new(@host, @port)
      @io = BufferedIO.new(@socket)
      handshake
    end

    HELLO = "HELLO 3 \r\n"
    def handshake
      @socket.write(HELLO)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
      p @io.read_line
    end

    def read_response
      
      p IO.select([@socket], nil, nil, @timeout)
      p @socket.read_nonblock(8_196, exception: false)

    end
  end

  def test_stuff
    client = RedisServer.new
    client.connect
  end
end
