# frozen_string_literal: true

require_relative "ilink/version"
require_relative "ilink/errors"
require_relative "ilink/constants"
require_relative "ilink/configuration"
require_relative "ilink/connection"
require_relative "ilink/bot"

module ILink
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
