# frozen_string_literal: true

class MeddlingMessageMiddleware
  # Message middlewares have the following KWargs available to them

  # parsed_data => Raw JSON of schema
  # schema => Schematized objected of data. schema.payload.event has much of the data you will want to mess with
  # socket_event => The socket_event object that was given -- Unlikely you need to play with this
  # listener => { handler:, on_success:, on_failure: } if the listener exists for the schema type; will be nil otherwise
  # type => will be one of :message, :ope, :close
  # websocket => The websocket client attached to Slack
  def call(parsed_data:, schema:, socket_event:, listener:, type:, websocket:)
    ###
    # Code to execute BEFORE the listener handler is called
    ###
    puts "I get called BEFORE the Handler gets executed"



    # The middleware chain is broken if yield is not called
    # If provided, the listener handler will not get called either
    # There may be occasions when you want to halt the middleware chain, but
    # for the most part, ensure you always yield
    yield



    ###
    # Code to execute AFTER the listener handler is called
    ###
    puts "I get called AFTER the Handler gets executed"
  end
end
