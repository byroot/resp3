require "test_helper"

class RESP3Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RESP3::VERSION
  end

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

  private

  def assert_parses(expected, payload)
    if expected == nil
      assert_nil RESP3.load(payload)
    else
      assert_equal(expected, RESP3.load(payload))
    end
  end
end
