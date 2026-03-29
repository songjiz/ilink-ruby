# frozen_string_literal: true

require_relative "test_helper"

class ConfigurationTest < Minitest::Test
  include ILinkTestHelper

  def test_default_values
    config = ILink::Configuration.new
    assert_equal "https://ilinkai.weixin.qq.com", config.base_url
    assert_equal "bot", config.app_id
    assert_equal "2.1.1", config.app_version
    assert_equal 15, config.timeout
    assert_equal 35, config.long_poll_timeout
    assert_nil config.token
    assert_nil config.route_tag
  end

  def test_global_configure
    ILink.configure do |c|
      c.token = "my_token"
      c.base_url = "https://custom.example.com"
    end

    assert_equal "my_token", ILink.configuration.token
    assert_equal "https://custom.example.com", ILink.configuration.base_url
  end

  def test_reset_configuration
    ILink.configure { |c| c.token = "abc" }
    ILink.reset_configuration!
    assert_nil ILink.configuration.token
  end

  def test_client_version_int
    config = ILink::Configuration.new
    config.app_version = "2.1.11"
    # 0x0002010B = (2 << 16) | (1 << 8) | 11 = 131339
    assert_equal 131339, config.client_version_int
  end

  def test_client_version_int_default
    config = ILink::Configuration.new
    # "2.1.1" => (2 << 16) | (1 << 8) | 1 = 131329
    assert_equal 131329, config.client_version_int
  end
end
