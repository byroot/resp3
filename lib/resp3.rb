# frozen_string_literal: true

require "resp3/version"
require "strscan"

module RESP3
  Error = Class.new(StandardError)
  UnknownType = Class.new(Error)

  TYPES = {
    '$' => :parse_blob,
    '+' => :read_line,
    '-' => :read_line,
    ':' => :parse_integer,
    '(' => :parse_integer,
    ',' => :parse_double,
    '_' => :parse_null,
  }.freeze
  SIGILS = Regexp.union(TYPES.keys.map { |sig| Regexp.new(Regexp.escape(sig)) })
  EOL = /\r\n/

  class << self
    def load(payload)
      parse(StringScanner.new(payload))
    end

    private

    def read_line(scanner)
      scanner.scan_until(EOL).byteslice(0..-3)
    end

    def parse(scanner)
      if type = scanner.scan(SIGILS)
        send(TYPES.fetch(type), scanner)
      else
        raise UnknownType, "Unknown sigil type: #{scanner.peek(1).inspect}"
      end
    end

    def parse_integer(scanner)
      Integer(read_line(scanner))
    end

    def parse_double(scanner)
      case value = read_line(scanner)
      when 'inf'
        Float::INFINITY
      when '-inf'
        -Float::INFINITY
      else
        Float(value)
      end
    end

    def parse_null(scanner)
      scanner.skip(EOL)
      nil
    end

    def parse_blob(scanner)
      bytesize = parse_integer(scanner)
      blob = scanner.peek(bytesize)
      scanner.pos += bytesize
      scanner.skip(EOL)
      blob
    end
  end
end
