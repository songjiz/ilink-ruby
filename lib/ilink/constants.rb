# frozen_string_literal: true

module ILink
  # Media type for upload requests
  module UploadMediaType
    IMAGE = 1
    VIDEO = 2
    FILE  = 3
    VOICE = 4
  end

  # Message sender type
  module MessageType
    NONE = 0
    USER = 1
    BOT  = 2
  end

  # Message content type
  module MessageItemType
    NONE  = 0
    TEXT  = 1
    IMAGE = 2
    VOICE = 3
    FILE  = 4
    VIDEO = 5
  end

  # Message lifecycle state
  module MessageState
    NEW        = 0
    GENERATING = 1
    FINISH     = 2
  end

  # Typing indicator status
  module TypingStatus
    TYPING = 1
    CANCEL = 2
  end
end
