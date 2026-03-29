# frozen_string_literal: true

require_relative "test_helper"

class ConstantsTest < Minitest::Test
  def test_upload_media_type
    assert_equal 1, ILink::UploadMediaType::IMAGE
    assert_equal 2, ILink::UploadMediaType::VIDEO
    assert_equal 3, ILink::UploadMediaType::FILE
    assert_equal 4, ILink::UploadMediaType::VOICE
  end

  def test_message_type
    assert_equal 0, ILink::MessageType::NONE
    assert_equal 1, ILink::MessageType::USER
    assert_equal 2, ILink::MessageType::BOT
  end

  def test_message_item_type
    assert_equal 1, ILink::MessageItemType::TEXT
    assert_equal 2, ILink::MessageItemType::IMAGE
    assert_equal 3, ILink::MessageItemType::VOICE
    assert_equal 4, ILink::MessageItemType::FILE
    assert_equal 5, ILink::MessageItemType::VIDEO
  end

  def test_message_state
    assert_equal 0, ILink::MessageState::NEW
    assert_equal 1, ILink::MessageState::GENERATING
    assert_equal 2, ILink::MessageState::FINISH
  end

  def test_typing_status
    assert_equal 1, ILink::TypingStatus::TYPING
    assert_equal 2, ILink::TypingStatus::CANCEL
  end
end
