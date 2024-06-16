# frozen_string_literal: true

require "slack_bot/events/configuration"
require "slack_bot/events/client"
require "slack_bot/events/schemas/socket_payload"

module SlackBot
  module Events
    class Error < StandardError; end

    def self.configure
      yield configuration if block_given?
    end

    def self.configuration
      @configuration ||= SlackBot::Events::Configuration.new
    end

    def self.config
      configuration
    end

    def self.configuration=(object)
      if SlackBot::Events::Configuration === obj
        @configuration = object
        return @configuration
      end

      raise Error, "Expected configuration to be a SlackBot::Events::Configuration"
    end

    def self.register_listener(name:, handler:)
      config.register_listener(name: name, handler: handler)
    end

    def self.remove_listener(name:)
      config.remove_listener(name: name)
    end
  end
end
