# frozen_string_literal: true

module ILink
  # Main entry point for the iLink Bot API.
  #
  #   bot = ILink::Bot.new(token: "your_bot_token")
  #   bot.get_updates
  #   bot.send_text(to: "user_id", text: "Hello!")
  #   bot.upload_url(media_type: 1, to_user_id: "user_id", ...)
  #   bot.send_typing(user_id: "...", ticket: "...")
  #   bot.get_config(user_id: "...")
  #   bot.create_qr_code
  #
  class Bot
    attr_reader :configuration

    def initialize(token: nil, base_url: nil, **options)
      @configuration = ILink.configuration.dup
      @configuration.token    = token    if token
      @configuration.base_url = base_url if base_url

      options.each do |key, value|
        @configuration.public_send(:"#{key}=", value) if @configuration.respond_to?(:"#{key}=")
      end
    end

    # Long-poll for new messages.
    #
    # @param buf [String] opaque cursor from previous call ("" on first call)
    # @return [Hash] parsed response with :ret, :msgs, :get_updates_buf, etc.
    def get_updates(buf: "")
      connection.post("/ilink/bot/getupdates",
                       { get_updates_buf: buf },
                       timeout: @configuration.long_poll_timeout)
    rescue Net::ReadTimeout, Net::OpenTimeout
      { ret: 0, msgs: [], get_updates_buf: buf }
    end

    # Send a message.
    #
    # @param message [Hash] a WeixinMessage hash with keys like :to_user_id, :item_list, etc.
    # @return [Hash] parsed response
    def send_message(message)
      connection.post("/ilink/bot/sendmessage", { msg: message })
    end

    # Convenience: send a text message to a user.
    #
    # @param to [String] target user ID
    # @param text [String] message text
    # @param session_id [String, nil] optional session ID
    # @return [Hash]
    def send_text(to:, text:, session_id: nil)
      message = {
        to_user_id: to,
        message_type: MessageType::BOT,
        message_state: MessageState::FINISH,
        item_list: [
          { type: MessageItemType::TEXT, text_item: { text: text } }
        ]
      }
      message[:session_id] = session_id if session_id
      send_message(message)
    end

    # Get a pre-signed CDN upload URL.
    #
    # @param params [Hash] :filekey, :media_type, :to_user_id, :rawsize, :rawfilemd5,
    #   :filesize, :aeskey, :thumb_rawsize, :thumb_rawfilemd5, :thumb_filesize, :no_need_thumb
    # @return [Hash] { upload_param:, thumb_upload_param:, upload_full_url: }
    def upload_url(**params)
      connection.post("/ilink/bot/getuploadurl", params)
    end

    # Send a typing indicator.
    #
    # @param user_id [String] ilink user ID
    # @param ticket  [String] typing ticket (from get_config)
    # @return [Hash]
    def send_typing(user_id:, ticket:)
      set_typing(user_id: user_id, ticket: ticket, status: TypingStatus::TYPING)
    end

    # Cancel a typing indicator.
    #
    # @param user_id [String] ilink user ID
    # @param ticket  [String] typing ticket
    # @return [Hash]
    def cancel_typing(user_id:, ticket:)
      set_typing(user_id: user_id, ticket: ticket, status: TypingStatus::CANCEL)
    end

    def set_typing(user_id:, ticket:, status:)
      connection.post("/ilink/bot/sendtyping", {
        ilink_user_id: user_id,
        typing_ticket: ticket,
        status: status
      }, timeout: 10)
    end

    # Fetch bot config for a user (includes typing_ticket).
    #
    # @param user_id       [String]      ilink user ID
    # @param context_token [String, nil] optional context token
    # @return [Hash] { ret:, typing_ticket:, ... }
    def get_config(user_id:, context_token: nil)
      body = { ilink_user_id: user_id, context_token: context_token }.compact
      connection.post("/ilink/bot/getconfig", body, timeout: 10)
    end

    # Request a new QR code for login.
    #
    # @param bot_type [String] bot type identifier (default "3")
    # @return [Hash] { qrcode:, qrcode_img_content: }
    def qrcode(bot_type: "3")
      connection.get("/ilink/bot/get_bot_qrcode?bot_type=#{URI.encode_www_form_component(bot_type)}", timeout: 5)
    end

    # Poll QR code scan status (long-poll).
    #
    # @param qrcode [String] qrcode value from #create_qr_code
    # @return [Hash] { status:, bot_token:, ilink_bot_id:, baseurl:, ilink_user_id:, redirect_host: }
    def qrcode_status(qrcode:)
      connection.get("/ilink/bot/get_qrcode_status?qrcode=#{URI.encode_www_form_component(qrcode)}",
                      timeout: @configuration.long_poll_timeout)
    rescue Net::ReadTimeout, Net::OpenTimeout
      { status: "wait" }
    end

    private
      def connection
        Connection.new(@configuration)
      end
  end
end
