# frozen_string_literal: true
require "test_helper"

class ParserTest < Minitest::Test
  def test_load_blob_string
    assert_parses "Hello World!", "$12\r\nHello World!\r\n"
  end

  def test_load_simple_string
    assert_parses "Hello World!", "+Hello World!\r\n"
  end

  def test_load_integer
    assert_parses 42, ":42\r\n"
    assert_parses(-42, ":-42\r\n")
    assert_parses 3492890328409238509324850943850943825024385, "(3492890328409238509324850943850943825024385\r\n"
  end

  def test_load_double
    assert_parses 42.42, ",42.42\r\n"
    assert_parses(-42.42, ",-42.42\r\n")
    assert_parses Float::INFINITY, ",inf\r\n"
    assert_parses(-Float::INFINITY, ",-inf\r\n")
  end

  def test_load_null
    assert_parses nil, "_\r\n"
  end

  def test_load_boolean
    assert_parses true, "#t\r\n"
    assert_parses false, "#f\r\n"
  end

  def test_load_array
    assert_parses [1, 2, 3], "*3\r\n:1\r\n:2\r\n:3\r\n"
  end

  def test_load_set
    assert_parses Set['orange', 'apple', true, 100, 999], "~5\r\n+orange\r\n+apple\r\n#t\r\n:100\r\n:999\r\n"
  end

  def test_load_map
    assert_parses({'first' => 1, 'second' => 2}, "%2\r\n+first\r\n:1\r\n+second\r\n:2\r\n")
  end

  private

  def assert_parses(expected, payload)
    actual = RESP3::IOReader.new(StringIO.new(payload)).next_value
    if expected == nil
      assert_nil actual 
    else
      assert_equal(expected, actual)
    end
  end
end
