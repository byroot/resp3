# frozen_string_literal: true
require "test_helper"

require 'timeout'
require 'socket'

class RedisConnectionTest < Minitest::Test
  class PubSub
    HANDLERS = {
      'subscribe' => :handle_subscribe
    }

    def initialize(server)
      @server = server
      @block = nil
      @subscriptions_count = 0
      @psubscriptions_count = 0
    end

    def on_message(&block)
      @block = block
      self
    end

    def push(event)
      handler = HANDLERS.fetch(event.type) do
        raise "Unexpected event type: #{event.type.inspect}"
      end
      send(handler, *event.arguments)
    end

    def handle_subscribe(channel, subscriptions_count)
      @subscriptions_count = subscriptions_count
    end
  end

  class RedisServer
    TimeoutError = Class.new(::Timeout::Error)

    def initialize(host: 'localhost', port: 6379, timeout: 5)
      @host = host
      @port = port
      @socket = nil
      @timeout = timeout
      @pubsub = nil
    end

    def call(*args)
      send_command(*args)
      next_value
    end

    def send_command(*args)
      write(RESP3.dump(cast_args!(args)))
      nil
    end

    def pubsub
      raise 'AlreadySubscribed' if @pubsub
      @pubsub = PubSub.new(self)
    end

    def next_value
      case value = @reader.next_value
      when RESP3::Push
        @pubsub&.push(value)
      else
        value
      end
    end

    def connect
      @socket = TCPSocket.new(@host, @port)
      @reader = RESP3::IOReader.new(@socket)
      handshake
    end

    private

    HELLO = "HELLO 3 \r\n"
    def handshake
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)

      write(HELLO)
      case response = @reader.next_value
      when RESP3::ProtocolError
        raise response
      when Hash
        # fine
      else
        raise 'WAT'
      end
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

    def write(payload)
      @socket.write(payload) # TODO: use write_nonblock
      # case wv = @socket.write_nonblock(payload, exception: false)
      # when 
    end
  end

  def test_stuff
    client = RedisServer.new
    client.connect
    Thread.new do
      sleep 1
      client2 = RedisServer.new
      client2.connect
      
      10.times do |i|
        sleep 0.5
        client2.call('PUBLISH', 'my-channel', "message-#{i}")
      end
      # p client.call('UNSUBSCRIBE', 'my-channel')
    end
    p [:sub, client.call('SUBSCRIBE', 'my-channel', 'second-channel')]
    p [:sub_next, client.next_value]
    10.times do 
      p [:next_value]
      p client.next_value
    end
    p client.call('UNSUBSCRIBE')
    p client.next_value
    # p client.call('UNSUBSCRIBE')
  end

  def test_monitor
    client = RedisServer.new
    client.connect
    Thread.new do
      sleep 1
      client2 = RedisServer.new
      client2.connect
      
      10.times do |i|
        sleep 0.5
        client2.call('GET', "key-#{i}")
      end
    end
    p client.call('MONITOR')
    10.times do 
      p [:next_value]
      p client.next_value
    end
    p client.call('QUIT')
    p client.call('GET', 'A')
  end

  def test_stuff_2
    client = RedisServer.new
    client.connect
    10.times do |i|
      client.call('PUBLISH', 'channel', "message-#{i}")
    end
  end

  def test_pubsub
    client = RedisServer.new
    client.connect
    client.call('SUBSCRIBE', 'channel')
  end

  def test_old_redis
    client = RedisServer.new(port: 6380)
    client.connect
  end
end
