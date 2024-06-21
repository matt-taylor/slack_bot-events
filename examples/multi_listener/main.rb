# frozen_string_literal: true

require 'bundler/setup'

require "slack_bot-events"
require_relative "message_listener.rb"
require_relative "reaction_removed_listener.rb"

# The `name` must match a Event subscription type found
# https://api.slack.com/events

###
# In the examples below, on_success and on_failure are methods
# They can be left empty or a be a proc
###

# Register a listener for all reaction removed events
SlackBot::Events.register_listener(
  name: "reaction_removed",
  # Handler must respond to call with schema: and raw_data: KWARGS
  handler: ReactionRemovedListener,
  # on_success must respond to call with 1 arg of schema
  on_success: ReactionRemovedListener.method(:on_success),
  # on_failure must respond to call with 2 args of schema and error
  on_failure: ReactionRemovedListener.method(:on_failure),
)

# Register a listener for all messages sent to a channel the bot is added to
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
