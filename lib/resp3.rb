# frozen_string_literal: true

require "set"
require "strscan"

require "resp3/version"
require "resp3/parser"
require "resp3/serializer"

module RESP3
  Error = Class.new(StandardError)
  UnknownType = Class.new(Error)
  SyntaxError = Class.new(Error)

  class << self
    def load(payload)
      Parser.load(payload)
    end

    def dump(payload)
      Serializer.dump(payload)
    end
  end
end
