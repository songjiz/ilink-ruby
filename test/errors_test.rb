# frozen_string_literal: true

require_relative "test_helper"

class ErrorsTest < Minitest::Test
  def test_api_error_hierarchy
    assert ILink::ApiError < ILink::Error
    assert ILink::AuthenticationError < ILink::ApiError
    assert ILink::TimeoutError < ILink::Error
  end

  def test_api_error_attributes
    error = ILink::ApiError.new(422, '{"errmsg":"bad request"}')
    assert_equal 422, error.status
    assert_equal '{"errmsg":"bad request"}', error.body
    assert_match(/422/, error.message)
  end
end
