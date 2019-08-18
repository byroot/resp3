# frozen_string_literal: true

module RESP3
  module Serializer
    EOL = "\r\n"
    TYPES = {
      String => :dump_string,
      Integer => :dump_integer,
      Float => :dump_float,
    }
    private_constant :TYPES

    INTEGER_RANGE = ((2**64 / 2) * -1)..((2**64 / 2) - 1)

    class << self
      def dump(payload, buffer=String.new(encoding: Encoding::BINARY, capacity: 1_024))
        send(TYPES.fetch(payload.class), payload, buffer)
      end

      private

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
        buffer << '$' << payload.bytesize.to_s << EOL << payload << EOL
      end
    end
  end
end
