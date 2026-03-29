# frozen_string_literal: true

module ILink
  class Configuration
    attr_accessor :base_url, :token
    attr_accessor :app_id, :app_version
    attr_accessor :timeout, :long_poll_timeout, :route_tag

    DEFAULT_BASE_URL          = "https://ilinkai.weixin.qq.com"
    DEFAULT_APP_ID            = "bot"
    DEFAULT_APP_VERSION       = "2.1.1"
    DEFAULT_TIMEOUT           = 15
    DEFAULT_LONG_POLL_TIMEOUT = 35

    def initialize
      @base_url          = DEFAULT_BASE_URL
      @app_id            = DEFAULT_APP_ID
      @app_version       = DEFAULT_APP_VERSION
      @timeout           = DEFAULT_TIMEOUT
      @long_poll_timeout = DEFAULT_LONG_POLL_TIMEOUT
      @token             = nil
      @route_tag         = nil
    end

    # Encode version string "M.N.P" as uint32: 0x00MMNNPP
    def client_version_int
      parts = (app_version || "0.0.0").split(".").map(&:to_i)
      ((parts[0] & 0xFF) << 16) | ((parts[1].to_i & 0xFF) << 8) | (parts[2].to_i & 0xFF)
    end
  end
end
