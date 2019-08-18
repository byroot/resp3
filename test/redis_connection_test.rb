# frozen_string_literal: true
require "test_helper"

require 'timeout'
require 'socket'

class RedisConnectionTest < Minitest::Test
  class RedisServer
    TimeoutError = Class.new(::Timeout::Error)

    def initialize(host: 'localhost', port: 6379)
      @host = host
      @port = port
      @socket = nil
      @timeout = 5
    end

    def call(*args)
      @socket.write(RESP3.dump(cast_args!(args)))
      @reader.next_value
    end

    def connect
      @socket = TCPSocket.new(@host, @port)
      @reader = RESP3::IOReader.new(@socket)
      handshake
    end

    HELLO = "HELLO 3 \r\n"
    def handshake
      @socket.write(HELLO)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
      p @reader.next_value
    end

    def cast_args!(args)
      args.map! do |arg|
        case arg
        when Hash
          arg.flat_map do |key, value|
            [key.to_s.upcase, value.to_s]
          end
        else
          arg.to_s
        end
      end
      args.flatten!
      args
    end

    def read_response
      
      p IO.select([@socket], nil, nil, @timeout)
      p @socket.read_nonblock(8_196, exception: false)

    end
  end

  def test_stuff
    client = RedisServer.new
    client.connect
    p client.call('SET', 'foo', 'bar', ex: 60)
    p client.call('TTL', 'foo')
    p s = client.call('GET', 'foo')
    p s.encoding
  end

  def test_old_redis
    client = RedisServer.new(port: 6380)
    client.connect
  end
end
