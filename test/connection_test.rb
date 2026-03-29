# frozen_string_literal: true

require_relative "test_helper"

class ConnectionTest < Minitest::Test
  include ILinkTestHelper

  def test_get_sends_common_headers
    stub_request(:get, "#{BASE_URL}/ilink/bot/get_bot_qrcode?bot_type=3")
      .with(headers: { "iLink-App-Id" => "bot" })
      .to_return(status: 200, body: '{"qrcode":"abc"}')

    conn = ILink::Connection.new(ILink::Configuration.new)
    conn.get("/ilink/bot/get_bot_qrcode?bot_type=3")
  end

  def test_post_sends_auth_and_ilink_headers
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .with(headers: {
        "Content-Type" => "application/json",
        "AuthorizationType" => "ilink_bot_token",
        "Authorization" => "Bearer my_secret",
        "iLink-App-Id" => "bot"
      })
      .to_return(status: 200, body: '{"ret":0}')

    config = ILink::Configuration.new
    config.token = "my_secret"
    conn = ILink::Connection.new(config)
    conn.post("/ilink/bot/sendmessage", { msg: {} })
  end

  def test_post_includes_base_info
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .with { |req| JSON.parse(req.body)["base_info"]["channel_version"] == "2.1.1" }
      .to_return(status: 200, body: '{"ret":0}')

    conn = ILink::Connection.new(ILink::Configuration.new)
    conn.post("/ilink/bot/sendmessage", { msg: {} })
  end

  def test_post_sends_route_tag_when_configured
    stub_request(:post, "#{BASE_URL}/ilink/bot/getconfig")
      .with(headers: { "SKRouteTag" => "42" })
      .to_return(status: 200, body: '{"ret":0}')

    config = ILink::Configuration.new
    config.route_tag = "42"
    conn = ILink::Connection.new(config)
    conn.post("/ilink/bot/getconfig", {})
  end

  def test_post_omits_auth_header_without_token
    stub = stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .to_return(status: 200, body: '{"ret":0}')

    conn = ILink::Connection.new(ILink::Configuration.new)
    conn.post("/ilink/bot/sendmessage", {})

    assert_requested(stub)
    # Verify no Authorization header was sent
    assert_requested(:post, "#{BASE_URL}/ilink/bot/sendmessage") { |req|
      !req.headers.key?("Authorization")
    }
  end

  def test_handle_401_raises_authentication_error
    stub_post("/ilink/bot/sendmessage", status: 401, response_body: { errmsg: "unauthorized" })

    conn = ILink::Connection.new(ILink::Configuration.new)
    assert_raises(ILink::AuthenticationError) do
      conn.post("/ilink/bot/sendmessage", {})
    end
  end

  def test_handle_403_raises_authentication_error
    stub_post("/ilink/bot/sendmessage", status: 403, response_body: { errmsg: "forbidden" })

    conn = ILink::Connection.new(ILink::Configuration.new)
    assert_raises(ILink::AuthenticationError) do
      conn.post("/ilink/bot/sendmessage", {})
    end
  end

  def test_handle_500_raises_api_error
    stub_post("/ilink/bot/sendmessage", status: 500, response_body: { errmsg: "internal" })

    conn = ILink::Connection.new(ILink::Configuration.new)
    error = assert_raises(ILink::ApiError) do
      conn.post("/ilink/bot/sendmessage", {})
    end
    assert_equal 500, error.status
  end

  def test_get_parses_json_response
    stub_get("/ilink/bot/get_bot_qrcode?bot_type=3",
             response_body: { qrcode: "abc", qrcode_img_content: "https://img.url" })

    conn = ILink::Connection.new(ILink::Configuration.new)
    result = conn.get("/ilink/bot/get_bot_qrcode?bot_type=3")

    assert_equal "abc", result[:qrcode]
    assert_equal "https://img.url", result[:qrcode_img_content]
  end
end
