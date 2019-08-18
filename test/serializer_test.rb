# frozen_string_literal: true
require "test_helper"

class SerializerTest < Minitest::Test
  def test_dump_string
    assert_dumps "Hello World!", "+Hello World!\r\n"
    assert_dumps "Hello\r\nWorld!", "$13\r\nHello\r\nWorld!\r\n"
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

  def test_dump_array
    assert_dumps [1, 2, 3], "*3\r\n:1\r\n:2\r\n:3\r\n"
  end

  def test_dump_set
    assert_dumps Set[1, 2, 3], "~3\r\n:1\r\n:2\r\n:3\r\n"
  end

  def test_dump_hash
    assert_dumps({'first' => 1, 'second' => 2}, "%2\r\n+first\r\n:1\r\n+second\r\n:2\r\n")
  end

  private

  def assert_dumps(payload, expected)
    assert_equal expected.encode(Encoding::BINARY), RESP3.dump(payload)
  end
end
