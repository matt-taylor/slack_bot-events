# frozen_string_literal: true

require "eventmachine"
require "faraday"
require "faye/websocket"
require "slack_bot/events/schematize"

module SlackBot
  module Events
    class Client
      BASE_API = "https://slack.com/api"

      def start!
        EventMachine.run do
           websocket.on :open do |socket_event|
            process(type: :open, socket_event: socket_event) { |**| }
          end

          websocket.on :message do |socket_event|
            process_message(socket_event: socket_event) do |listener:, parsed_data:, schema: nil|
              case parsed_data["type"]
              when "events_api"
                events_api(handler: listener&.dig(:handler), schema: schema, parsed_data: parsed_data)
              end
            end
          end

          websocket.on :close do |socket_event|
            process(type: :close, socket_event: socket_event) { |**| }
            @websocket = nil

            # The websocket is closed, explcitly stop the event machine to to end the loop and return to the parent
            EventMachine.stop
          end
        end
      end

      def process_message(socket_event:)
        schema_data = Schematize.call(data: socket_event.data)

        listener = find_listener(schema: schema_data[:schema]) # Events.config.listeners[schema_data[:schema]&.type.to_sym]

        SlackBot::Events.message_middleware.invoke_message(websocket: websocket, listener: listener, type: :message, socket_event: socket_event, **schema_data) do
          yield(listener: listener, **schema_data) if block_given?
        end
      end

      def process(type:, socket_event:)
        SlackBot::Events.public_send(:"#{type}_middleware").invoke(type: type, socket_event: socket_event) do
          yield if block_given?
        end
      end

      def events_api(handler:, schema:, parsed_data:)
        return if handler.nil?

        Events.logger.info { schema.tldr } if Events.config.print_tldr

        # This gets rescued in the MessageHandler middleware
        # on_success and on_failure happens there as well
        handler.call(schema: schema, raw_data: parsed_data)
      end

      private

      def find_listener(schema:)
        return nil if schema.nil?

        Events.config.listeners[schema.type.to_sym]
      end

      def websocket
        @websocket ||= Faye::WebSocket::Client.new(socket_endpoint)
      end

      # TODO: Error handling here
      def socket_endpoint
        result = faraday_client.post("apps.connections.open")
        json_body = JSON.parse(result.body)
        json_body["url"]
      end

      def faraday_client
        @faraday_client ||= Faraday.new(url: "https://slack.com/api", headers: faraday_headers)
      end

      def faraday_headers
        { 'Authorization' => "Bearer #{SlackBot::Events.config.client_socket_token}" }
      end
    end
  end
end
