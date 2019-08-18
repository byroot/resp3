# frozen_string_literal: true
require "test_helper"

class SerializerTest < Minitest::Test
  def test_dump_string
    assert_dumps "Hello World!", "$12\r\nHello World!\r\n"
  end

  private

  def assert_dumps(payload, expected)
    assert_equal expected.encode(Encoding::BINARY), RESP3.dump(payload)
  end
end
