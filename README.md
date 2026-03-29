# ILink

Ruby SDK for the WeChat iLink Bot API.

## Installation

```ruby
# Gemfile
gem "ilink"
```

Or install directly:

```sh
gem install ilink
```

## Quick Start

```ruby
require "ilink"

ILink.configure do |c|
  c.token = "your_bot_token"
end

bot = ILink::Bot.new
```

## Configuration

| Option              | Default                         | Description                                                     |
| ------------------- | ------------------------------- | --------------------------------------------------------------- |
| `base_url`          | `https://ilinkai.weixin.qq.com` | API base URL                                                    |
| `token`             | `nil`                           | Bot token (Bearer auth)                                         |
| `app_id`            | `"bot"`                         | iLink-App-Id header                                             |
| `app_version`       | `"2.1.1"`                       | Client version string                                           |
| `timeout`           | `15`                            | Default request timeout (seconds)                               |
| `long_poll_timeout` | `35`                            | Long-poll timeout for `get_updates` / `qrcode_status` (seconds) |
| `route_tag`         | `nil`                           | Optional SKRouteTag header                                      |

Global configuration applies to all `Bot` instances. You can also override per-instance:

```ruby
bot = ILink::Bot.new(
  token: "another_token",
  base_url: "https://custom-host.example.com"
)
```

## API Reference

### QR Code Login

```ruby
bot = ILink::Bot.new

# Step 1: Get a QR code
qr = bot.get_qrcode
puts qr[:qrcode_img_content]  # QR code image URL — show to user

# Step 2: Poll scan status (long-poll, blocks until scanned or timeout)
loop do
  status = bot.get_qrcode_status(qrcode: qr[:qrcode])
  case status[:status]
  when "confirmed"
    puts "Login success!"
    puts "bot_token:     #{status[:bot_token]}"
    puts "ilink_bot_id:  #{status[:ilink_bot_id]}"
    puts "base_url:      #{status[:baseurl]}"
    break
  when "scaned"
    puts "Scanned, waiting for confirmation..."
  when "expired"
    puts "QR code expired, request a new one"
    break
  when "scaned_but_redirect"
    # IDC redirect — switch polling host
    puts "Redirecting to #{status[:redirect_host]}"
  end
end
```

### Polling Messages

```ruby
bot = ILink::Bot.new(token: "your_bot_token")

buf = ""
loop do
  resp = bot.get_updates(buf: buf)
  buf = resp[:get_updates_buf] || buf

  (resp[:msgs] || []).each do |msg|
    from = msg[:from_user_id]
    msg[:item_list]&.each do |item|
      case item[:type]
      when ILink::MessageItemType::TEXT
        puts "#{from}: #{item[:text_item][:text]}"
      when ILink::MessageItemType::IMAGE
        puts "#{from}: [image] #{item[:image_item][:url]}"
      end
    end
  end
end
```

### Sending Messages

```ruby
# Send a simple text message
bot.send_text(to: "user_id", text: "Hello from Ruby!")

# Send with session ID
bot.send_text(to: "user_id", text: "Reply in session", session_id: "session_123")

# Send a custom message (image, file, video, etc.)
bot.send_message({
  to_user_id: "user_id",
  message_type: ILink::MessageType::BOT,
  message_state: ILink::MessageState::FINISH,
  item_list: [
    {
      type: ILink::MessageItemType::IMAGE,
      image_item: {
        media: { encrypt_query_param: "...", aes_key: "..." }
      }
    }
  ]
})
```

### Media Upload

```ruby
resp = bot.get_upload_url(
  media_type:  ILink::UploadMediaType::IMAGE,
  to_user_id:  "user_id",
  rawsize:     File.size("photo.jpg"),
  rawfilemd5:  Digest::MD5.hexdigest(File.read("photo.jpg")),
  filesize:    encrypted_size,
  aeskey:      aes_key_hex
)

puts resp[:upload_full_url]        # Pre-signed upload URL
puts resp[:upload_param]           # Upload encryption param
puts resp[:thumb_upload_param]     # Thumbnail upload param (if applicable)
```

### Typing Indicators

```ruby
# Get the typing ticket first
config = bot.get_config(user_id: "user_id")
ticket = config[:typing_ticket]

# Show "typing..."
bot.send_typing(user_id: "user_id", ticket: ticket)

# Cancel typing
bot.cancel_typing(user_id: "user_id", ticket: ticket)
```

### Bot Config

```ruby
config = bot.get_config(user_id: "user_id", context_token: "optional_token")
puts config[:typing_ticket]
```

## Constants

```ruby
ILink::UploadMediaType::IMAGE  # 1
ILink::UploadMediaType::VIDEO  # 2
ILink::UploadMediaType::FILE   # 3
ILink::UploadMediaType::VOICE  # 4

ILink::MessageType::USER       # 1
ILink::MessageType::BOT        # 2

ILink::MessageItemType::TEXT   # 1
ILink::MessageItemType::IMAGE  # 2
ILink::MessageItemType::VOICE  # 3
ILink::MessageItemType::FILE   # 4
ILink::MessageItemType::VIDEO  # 5

ILink::MessageState::NEW        # 0
ILink::MessageState::GENERATING # 1
ILink::MessageState::FINISH     # 2

ILink::TypingStatus::TYPING    # 1
ILink::TypingStatus::CANCEL    # 2
```

## Error Handling

```ruby
begin
  bot.send_text(to: "user_id", text: "hi")
rescue ILink::AuthenticationError => e
  puts "Auth failed (#{e.status}): #{e.body}"
rescue ILink::ApiError => e
  puts "API error (#{e.status}): #{e.body}"
rescue Net::ReadTimeout
  puts "Request timed out"
end
```

## Full Echo Bot Example

```ruby
require "ilink"

ILink.configure do |c|
  c.token = ENV["ILINK_BOT_TOKEN"]
end

bot = ILink::Bot.new
buf = ""

puts "Bot started, waiting for messages..."

loop do
  resp = bot.get_updates(get_updates_buf: buf)
  buf = resp[:get_updates_buf] || buf

  (resp[:msgs] || []).each do |msg|
    next unless msg[:message_type] == ILink::MessageType::USER

    from = msg[:from_user_id]
    msg[:item_list]&.each do |item|
      next unless item[:type] == ILink::MessageItemType::TEXT

      text = item.dig(:text_item, :text)
      puts "Received: #{text} from #{from}"
      bot.send_text(to: from, text: "Echo: #{text}", session_id: msg[:session_id])
    end
  end
rescue ILink::ApiError => e
  warn "API error: #{e.message}"
  sleep 3
end
```

## License

MIT
