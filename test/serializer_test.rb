# frozen_string_literal: true
require "test_helper"

class SerializerTest < Minitest::Test
  def test_dump_string
    assert_dumps "Hello World!", "$12\r\nHello World!\r\n"
  end

  def test_dump_integer
    assert_dumps 42, ":42\r\n"
  end

  def test_dump_big_integer
    assert_dumps 1_000_000_000_000_000_000_000, "(1000000000000000000000\r\n"
  end

  def test_dump_float
    assert_dumps 42.42, ",42.42\r\n"
    assert_dumps Float::INFINITY, ",inf\r\n"
    assert_dumps(-Float::INFINITY, ",-inf\r\n")
  end

  private

  def assert_dumps(payload, expected)
    assert_equal expected.encode(Encoding::BINARY), RESP3.dump(payload)
  end
end
