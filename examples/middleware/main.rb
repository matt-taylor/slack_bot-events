# frozen_string_literal: true

require 'bundler/setup'

require "slack_bot-events"
require_relative "message_listener.rb"
require_relative "meddling_message_middleware.rb"

SlackBot::Events.configure do |c|
  c.message_middleware.add(MeddlingMessageMiddleware)
  c.print_tldr = false
end

SlackBot::Events.register_listener(
  name: "message",
  handler: MessageListener,
  on_success: MessageListener.method(:on_success),
  on_failure: MessageListener.method(:on_failure),
)

SlackBot::Events::Client.new.start!
