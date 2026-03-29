# frozen_string_literal: true

require_relative "lib/ilink/version"

Gem::Specification.new do |spec|
  spec.name          = "ilink"
  spec.version       = ILink::VERSION
  spec.authors       = ["Songji Zeng"]
  spec.summary       = "Ruby SDK for the WeChat iLink Bot API"
  spec.description   = <<~DESC
  A lightweight Ruby SDK for building WeChat bots via the iLink Bot API.
  Handles QR login, long-polling for messages, sending replies, and typing indicators.
  DESC
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
end
