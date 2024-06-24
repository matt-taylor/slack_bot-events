# frozen_string_literal: true

class MeddlingMessageMiddleware
  # Message middlewares have the following KWargs available to them
  def call(parsed_data:, schema:, socket_event:, listener:, type:, websocket:)
    puts "I get called BEFORE the Handler gets executed"

    puts "But wait! There is no yield, Message Handler never gets called"
  end
end
