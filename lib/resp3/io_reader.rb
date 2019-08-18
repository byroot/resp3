# frozen_string_literal: true

module RESP3
  class IOReader
    def initialize(io, timeout: 5, buffer_size: 8_196)
      @buffer_size = buffer_size
      @timeout = timeout

      @io = io
      @buffer = String.new(capacity: buffer_size, encoding: Encoding::BINARY)
    end

    def next_value
      Parser.parse(self)
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
        case rv = @io.read_nonblock(@buffer_size, @buffer, exception: false)
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
end
