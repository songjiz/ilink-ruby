# frozen_string_literal: true

require_relative "test_helper"

class BotTest < Minitest::Test
  include ILinkTestHelper

  def test_get_updates_returns_messages
    stub_post("/ilink/bot/getupdates", response_body: {
      ret: 0,
      msgs: [{ from_user_id: "u1", item_list: [{ type: 1, text_item: { text: "hi" } }] }],
      get_updates_buf: "buf_123"
    })

    resp = new_bot.get_updates
    assert_equal 0, resp[:ret]
    assert_equal 1, resp[:msgs].length
    assert_equal "buf_123", resp[:get_updates_buf]
  end

  def test_get_updates_sends_get_updates_buf
    stub_request(:post, "#{BASE_URL}/ilink/bot/getupdates")
      .with { |req| JSON.parse(req.body)["get_updates_buf"] == "cursor_abc" }
      .to_return(status: 200, body: '{"ret":0,"msgs":[]}')

    new_bot.get_updates(buf: "cursor_abc")
  end

  def test_get_updates_returns_empty_on_timeout
    stub_request(:post, "#{BASE_URL}/ilink/bot/getupdates").to_timeout

    resp = new_bot.get_updates(buf: "old_buf")
    assert_equal 0, resp[:ret]
    assert_equal [], resp[:msgs]
    assert_equal "old_buf", resp[:get_updates_buf]
  end

  def test_send_message
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .with { |req| JSON.parse(req.body)["msg"]["to_user_id"] == "u1" }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.send_message({ to_user_id: "u1", item_list: [] })
  end

  def test_send_text_builds_correct_payload
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .with { |req|
        msg = JSON.parse(req.body)["msg"]
        msg["to_user_id"] == "user_42" &&
          msg["message_type"] == ILink::MessageType::BOT &&
          msg["message_state"] == ILink::MessageState::FINISH &&
          msg["item_list"][0]["type"] == ILink::MessageItemType::TEXT &&
          msg["item_list"][0]["text_item"]["text"] == "Hello!"
      }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.send_text(to: "user_42", text: "Hello!")
  end

  def test_send_text_with_session_id
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .with { |req| JSON.parse(req.body)["msg"]["session_id"] == "sess_1" }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.send_text(to: "u1", text: "hi", session_id: "sess_1")
  end

  def test_upload_url
    stub_post("/ilink/bot/getuploadurl", response_body: {
      upload_full_url: "https://cdn.example.com/upload",
      upload_param: "enc_param"
    })

    resp = new_bot.upload_url(
      media_type: ILink::UploadMediaType::IMAGE,
      to_user_id: "u1",
      rawsize: 1024,
      rawfilemd5: "abc123"
    )

    assert_equal "https://cdn.example.com/upload", resp[:upload_full_url]
    assert_equal "enc_param", resp[:upload_param]
  end

  def test_upload_url_sends_params
    stub_request(:post, "#{BASE_URL}/ilink/bot/getuploadurl")
      .with { |req|
        body = JSON.parse(req.body)
        body["media_type"] == ILink::UploadMediaType::IMAGE &&
          body["to_user_id"] == "u1" &&
          body["rawsize"] == 1024
      }
      .to_return(status: 200, body: '{}')

    new_bot.upload_url(media_type: ILink::UploadMediaType::IMAGE, to_user_id: "u1", rawsize: 1024)
  end

  def test_send_typing
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendtyping")
      .with { |req|
        body = JSON.parse(req.body)
        body["ilink_user_id"] == "u1" &&
          body["typing_ticket"] == "tkt_abc" &&
          body["status"] == ILink::TypingStatus::TYPING
      }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.send_typing(user_id: "u1", ticket: "tkt_abc")
  end

  def test_cancel_typing
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendtyping")
      .with { |req| JSON.parse(req.body)["status"] == ILink::TypingStatus::CANCEL }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.cancel_typing(user_id: "u1", ticket: "tkt_abc")
  end

  def test_get_config
    stub_post("/ilink/bot/getconfig", response_body: { ret: 0, typing_ticket: "ticket_xyz" })

    resp = new_bot.get_config(user_id: "u1")
    assert_equal 0, resp[:ret]
    assert_equal "ticket_xyz", resp[:typing_ticket]
  end

  def test_get_config_sends_user_id
    stub_request(:post, "#{BASE_URL}/ilink/bot/getconfig")
      .with { |req| JSON.parse(req.body)["ilink_user_id"] == "u1" }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.get_config(user_id: "u1")
  end

  def test_get_config_with_context_token
    stub_request(:post, "#{BASE_URL}/ilink/bot/getconfig")
      .with { |req| JSON.parse(req.body)["context_token"] == "ctx_123" }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.get_config(user_id: "u1", context_token: "ctx_123")
  end

  def test_get_config_omits_nil_context_token
    stub_request(:post, "#{BASE_URL}/ilink/bot/getconfig")
      .with { |req| !JSON.parse(req.body).key?("context_token") }
      .to_return(status: 200, body: '{"ret":0}')

    new_bot.get_config(user_id: "u1")
  end

  def test_qrcode
    stub_get("/ilink/bot/get_bot_qrcode?bot_type=3", response_body: {
      qrcode: "qr_abc",
      qrcode_img_content: "https://img.url/qr.png"
    })

    resp = new_bot.qrcode
    assert_equal "qr_abc", resp[:qrcode]
    assert_equal "https://img.url/qr.png", resp[:qrcode_img_content]
  end

  def test_qrcode_with_custom_bot_type
    stub_get("/ilink/bot/get_bot_qrcode?bot_type=5", response_body: { qrcode: "qr" })

    resp = new_bot.qrcode(bot_type: "5")
    assert_equal "qr", resp[:qrcode]
  end

  def test_qrcode_status_confirmed
    stub_get("/ilink/bot/get_qrcode_status?qrcode=qr_abc", response_body: {
      status: "confirmed",
      bot_token: "token_123",
      ilink_bot_id: "bot_456",
      baseurl: "https://new.host.com"
    })

    resp = new_bot.qrcode_status(qrcode: "qr_abc")
    assert_equal "confirmed", resp[:status]
    assert_equal "token_123", resp[:bot_token]
    assert_equal "bot_456", resp[:ilink_bot_id]
  end

  def test_qrcode_status_returns_wait_on_timeout
    stub_request(:get, "#{BASE_URL}/ilink/bot/get_qrcode_status?qrcode=qr_abc").to_timeout

    resp = new_bot.qrcode_status(qrcode: "qr_abc")
    assert_equal "wait", resp[:status]
  end

  def test_per_instance_token_override
    stub_request(:post, "#{BASE_URL}/ilink/bot/sendmessage")
      .with(headers: { "Authorization" => "Bearer override_token" })
      .to_return(status: 200, body: '{"ret":0}')

    ILink.configure { |c| c.token = "global_token" }
    bot = ILink::Bot.new(token: "override_token")
    bot.send_text(to: "u1", text: "hi")
  end

  def test_authentication_error_on_401
    stub_post("/ilink/bot/sendmessage", status: 401, response_body: { errmsg: "bad token" })

    error = assert_raises(ILink::AuthenticationError) do
      new_bot.send_text(to: "u1", text: "hi")
    end
    assert_equal 401, error.status
  end

  def test_api_error_on_500
    stub_post("/ilink/bot/getconfig", status: 500, response_body: { errmsg: "server error" })

    error = assert_raises(ILink::ApiError) do
      new_bot.get_config(user_id: "u1")
    end
    assert_equal 500, error.status
  end
end
