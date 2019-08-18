# frozen_string_literal: true

require "set"

require "resp3/version"
require "resp3/parser"
require "resp3/serializer"
require "resp3/io_reader"

module RESP3
  Error = Class.new(StandardError)
  UnknownType = Class.new(Error)
  SyntaxError = Class.new(Error)

  class << self
    def dump(payload)
      Serializer.dump(payload)
    end
  end
end
