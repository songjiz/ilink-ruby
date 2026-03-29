# frozen_string_literal: true

require_relative "lib/ilink/version"

Gem::Specification.new do |spec|
  spec.name          = "ilink"
  spec.version       = ILink::VERSION
  spec.authors       = ["Songji Zeng"]
  spec.email         = ["songji.zeng@outlook.com"]
  spec.summary       = "Ruby SDK for the WeChat iLink Bot API"
  spec.description   = <<~DESC
  A lightweight Ruby SDK for building WeChat bots via the iLink Bot API.
  Handles QR login, long-polling for messages, sending replies, and typing indicators.
  DESC
  spec.homepage      = "https://github.com/songjiz/ilink-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
end
