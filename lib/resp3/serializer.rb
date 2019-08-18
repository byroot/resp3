# frozen_string_literal: true

module RESP3
  module Serializer
    EOL = "\r\n"
    TYPES = {
      String => :dump_string,
      Integer => :dump_integer,
      Float => :dump_float,
      Array => :dump_array,
      Set => :dump_set,
      Hash => :dump_hash,
      TrueClass => :dump_true,
      FalseClass => :dump_false,
      NilClass => :dump_nil,
    }
    private_constant :TYPES

    INTEGER_RANGE = ((2**64 / 2) * -1)..((2**64 / 2) - 1)

    class << self
      def dump(payload, buffer=String.new(encoding: Encoding::BINARY, capacity: 1_024))
        send(TYPES.fetch(payload.class), payload, buffer)
      end

      private

      def dump_array(payload, buffer)
        buffer << '*' << payload.size.to_s << EOL
        payload.each do |item|
          dump(item, buffer)
        end
        buffer
      end

      def dump_set(payload, buffer)
        buffer << '~' << payload.size.to_s << EOL
        payload.each do |item|
          dump(item, buffer)
        end
        buffer
      end

      def dump_hash(payload, buffer)
        buffer << '%' << payload.size.to_s << EOL
        payload.each_pair do |key, value|
          dump(key, buffer)
          dump(value, buffer)
        end
        buffer
      end

      def dump_integer(payload, buffer)
        if INTEGER_RANGE.cover?(payload)
          buffer << ':' << payload.to_s << EOL
        else
          buffer << '(' << payload.to_s << EOL
        end
      end

      def dump_float(payload, buffer)
        buffer << ','
        case payload
        when Float::INFINITY
          buffer << 'inf'
        when -Float::INFINITY
          buffer << '-inf'
        else
           buffer << payload.to_s
        end
        buffer << EOL
      end

      def dump_string(payload, buffer)
        if !payload.ascii_only? || payload.match?(/[\r\n]/)
          buffer << '$' << payload.bytesize.to_s << EOL << payload << EOL
        else
          buffer << '+' << payload << EOL
        end
      end

      def dump_true(_payload, buffer)
        buffer << '#t' << EOL
      end

      def dump_false(_payload, buffer)
        buffer << '#f' << EOL
      end

      def dump_nil(_payload, buffer)
        buffer << '_' << EOL
      end
    end
  end
end
