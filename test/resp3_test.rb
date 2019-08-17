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
  end

  private

  def assert_parses(expected, payload)
    assert_equal(expected, RESP3.load(payload))
  end
end
