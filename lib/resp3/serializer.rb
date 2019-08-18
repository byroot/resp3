# frozen_string_literal: true

module RESP3
  module Serializer
    EOL = "\r\n"
    TYPES = {
      String => :dump_string,
    }
    private_constant :TYPES

    class << self
      def dump(payload, buffer=String.new(encoding: Encoding::BINARY, capacity: 1_024))
        send(TYPES.fetch(payload.class), payload, buffer)
      end

      private

      def dump_string(payload, buffer)
        buffer << '$' << payload.bytesize.to_s << EOL << payload << EOL
      end
    end
  end
end
