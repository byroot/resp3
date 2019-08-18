# frozen_string_literal: true
require "test_helper"

class RESP3Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RESP3::VERSION
  end
end
