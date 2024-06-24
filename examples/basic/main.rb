# frozen_string_literal: true

require 'bundler/setup'

require "slack_bot-events"
require_relative "message_listener.rb"

# The `name` must match a Event subscription type found
# https://api.slack.com/events

# Register a listener for all reaction removed events
SlackBot::Events.register_listener(
  name: "message",
  # Handler must respond to call with schema: and raw_data: KWARGS
  handler: MessageListener,
  # on_success must respond to call with 1 arg of schema
  on_success: MessageListener.method(:on_success),
  # on_failure must respond to call with 2 args of schema and error
  on_failure: MessageListener.method(:on_failure),
)


# This is a blocking way to start the Websocket client
# EventMachine is used to keep the socket open
# The process responds to all SigQuit/Term/Kill events as expected
SlackBot::Events::Client.new.start!
