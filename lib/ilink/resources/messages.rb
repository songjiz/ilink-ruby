# frozen_string_literal: true

module ILink
  module Resources
    # RESTful resource for message operations.
    #
    #   bot.messages.get_updates - long-poll for new messages (getUpdates)
    #   bot.messages.send(msg)   - send a message to a user
    class Messages < Base
      # Long-poll for new messages.
      #
      # @param get_updates_buf [String] opaque cursor from previous poll ("" on first call)
      # @return [Hash] parsed response with :ret, :msgs, :get_updates_buf, etc.
      def poll(get_updates_buf: "")
        post("/ilink/bot/getupdates",
             { get_updates_buf: get_updates_buf },
             timeout: connection.config.long_poll_timeout)
      rescue Net::ReadTimeout, Net::OpenTimeout
        # Long-poll timeout is normal; return empty response so caller can retry
        { ret: 0, msgs: [], get_updates_buf: get_updates_buf }
      end

      # Send a message.
      #
      # @param message [Hash] a WeixinMessage hash with keys like :to_user_id, :item_list, etc.
      # @return [Hash] parsed response
      def send(message)
        post("/ilink/bot/sendmessage", { msg: message })
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
            {
              type: MessageItemType::TEXT,
              text_item: { text: text }
            }
          ]
        }
        message[:session_id] = session_id if session_id
        send(message)
      end
    end
  end
end
