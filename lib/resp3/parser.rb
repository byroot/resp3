# frozen_string_literal: true

module RESP3
  module Parser
    TYPES = {
      '#' => :parse_boolean,
      '$' => :parse_blob,
      '+' => :noop,
      '-' => :noop,
      ':' => :parse_integer,
      '(' => :parse_integer,
      ',' => :parse_double,
      '_' => :parse_null,
      '*' => :parse_array,
      '%' => :parse_map,
      '~' => :parse_set,
    }.freeze
    SIGILS = Regexp.union(TYPES.keys.map { |sig| Regexp.new(Regexp.escape(sig)) })
    EOL = /\r\n/

    class << self
      def parse(io)
        value = io.read_line
        sigil = value.slice!(0, 1)
        handler = TYPES.fetch(sigil) do
          raise UnknownType, "Unknown sigil type: #{sigil.inspect}"
        end
        send(handler, value, io)
      end

      private

      def noop(value, _io)
        value
      end

      def parse_boolean(value, io)
        case value
        when 't'
          true
        when 'f'
          false
        else
          raise SyntaxError, "Expected `t` or `f` after `#`, got: #{value.inspect}"
        end
      end

      def parse_array(value, io)
        parse_sequence(Integer(value), io)
      end

      def parse_set(value, io)
        parse_sequence(Integer(value), io).to_set
      end

      def parse_map(value, io)
        Hash[*parse_sequence(Integer(value) * 2, io)]
      end

      def parse_sequence(size, io)
        array = Array.new(size)
        size.times do |index|
          array[index] = parse(io)
        end
        array
      end

      def parse_integer(value, _io)
        Integer(value)
      end

      def parse_double(value, _io)
        case value
        when 'inf'
          Float::INFINITY
        when '-inf'
          -Float::INFINITY
        else
          Float(value)
        end
      end

      def parse_null(value, _io)
        nil
      end

      def parse_blob(value, io)
        bytesize = Integer(value)
        io.read_bytes(bytesize)
      end
    end
  end
end
