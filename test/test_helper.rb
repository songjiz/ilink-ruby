# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require_relative "../lib/ilink"

BASE_URL = "https://ilinkai.weixin.qq.com"

module ILinkTestHelper
  def setup
    ILink.reset_configuration!
    WebMock.reset!
  end

  def new_bot(token: "test_token", **opts)
    ILink::Bot.new(token: token, **opts)
  end

  def stub_post(path, response_body: {}, status: 200)
    stub_request(:post, "#{BASE_URL}#{path}")
      .to_return(status: status, body: JSON.generate(response_body), headers: { "Content-Type" => "application/json" })
  end

  def stub_get(path, response_body: {}, status: 200)
    stub_request(:get, "#{BASE_URL}#{path}")
      .to_return(status: status, body: JSON.generate(response_body), headers: { "Content-Type" => "application/json" })
  end
end
