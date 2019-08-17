# frozen_string_literal: true

require "resp3/version"
require "strscan"

module RESP3
  Error = Class.new(StandardError)
  TYPES = {
    '$' => :parse_blob,
    '+' => :read_line,
    '-' => :read_line,
    ':' => :parse_integer,
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
      send(TYPES.fetch(scanner.scan(SIGILS)), scanner)
    end

    def parse_integer(scanner)
      read_line(scanner).to_i
    end

    def parse_blob(scanner)
      bytesize = parse_integer(scanner)
      blob = scanner.peek(bytesize)
      scanner.pos += bytesize + 2
      blob
    end
  end
end
