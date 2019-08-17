# frozen_string_literal: true

require "resp3/version"
require "set"
require "strscan"

module RESP3
  Error = Class.new(StandardError)
  UnknownType = Class.new(Error)
  SyntaxError = Class.new(Error)

  TYPES = {
    '#' => :parse_boolean,
    '$' => :parse_blob,
    '+' => :read_line,
    '-' => :read_line,
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

    def parse_boolean(scanner)
      case value = scanner.get_byte
      when 't'
        scanner.skip(EOL)
        true
      when 'f'
        scanner.skip(EOL)
        false
      else
        raise SyntaxError, "Expected `t` or `f` after `#`, got: #{value.inspect}"
      end
    end

    def parse_array(scanner)
      parse_sequence(scanner, parse_integer(scanner))
    end

    def parse_set(scanner)
      parse_sequence(scanner, parse_integer(scanner)).to_set
    end

    def parse_map(scanner)
      Hash[*parse_sequence(scanner, parse_integer(scanner) * 2)]
    end

    def parse_sequence(scanner, size)
      array = Array.new(size)
      size.times do |index|
        array[index] = parse(scanner)
      end
      array
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
