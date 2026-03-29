# frozen_string_literal: true

require "uri"
require "json"
require "base64"
require "securerandom"
require "net/http"

module ILink
  # Low-level HTTP connection using Ruby's built-in net/http.
  # Builds proper iLink headers, handles timeouts, and parses JSON responses.
  class Connection
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def get(endpoint, timeout: config.timeout, headers: {})
      uri = build_uri(endpoint)
      request = Net::HTTP::Get.new(uri)
      common_headers.merge(headers).each { |k, v| request[k] = v }

      execute(uri, request, timeout: timeout)
    end

    def post(endpoint, body = {}, timeout: config.timeout, headers: {})
      uri = build_uri(endpoint)
      payload = body.merge(base_info: { channel_version: config.app_version })
      json_body = JSON.generate(payload)

      request = Net::HTTP::Post.new(uri)
      post_headers.merge(headers).each { |k, v| request[k] = v }
      request.body = json_body

      execute(uri, request, timeout: timeout)
    end

    private
      def build_uri(endpoint)
        URI.join(config.base_url.to_s, endpoint)
      end

      def common_headers
        headers = {
          "iLink-App-Id"            => config.app_id,
          "iLink-App-ClientVersion" => config.client_version_int.to_s
        }
        headers["SKRouteTag"] = config.route_tag if config.route_tag
        headers
      end

      def post_headers
        headers = common_headers.merge(
          "Content-Type"      => "application/json",
          "AuthorizationType" => "ilink_bot_token",
          "X-WECHAT-UIN"     => random_wechat_uin
        )
        headers["Authorization"] = "Bearer #{config.token}" if config.token
        headers
      end

      def random_wechat_uin
        uint32 = SecureRandom.random_number(2**32)
        Base64.strict_encode64(uint32.to_s)
      end

      def execute(uri, request, timeout:)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl       = (uri.scheme == "https")
        http.open_timeout  = [timeout, 10].min
        http.read_timeout  = timeout
        http.write_timeout = timeout

        response = http.request(request)
        handle_response(response)
      end

      def handle_response(response)
        case response.code.to_i
        when 200..299
          body = response.body.to_s
          body.empty? ? {} : JSON.parse(body, symbolize_names: true)
        when 401, 403
          raise AuthenticationError.new(response.code.to_i, response.body)
        else
          raise ApiError.new(response.code.to_i, response.body)
        end
      end
  end
end
