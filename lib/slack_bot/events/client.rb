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
            process_message(socket_event: socket_event) do |parsed_data:, schema: nil|
              case parsed_data["type"]
              when "events_api"
                events_api(schema: schema, parsed_data: parsed_data)
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
        SlackBot::Events.message_middleware.invoke_message(type: :message, socket_event: socket_event, **schema_data) do
          yield(**schema_data) if block_given?
        end
      end

      def process(type:, socket_event:)
        SlackBot::Events.public_send(:"#{type}_middleware").invoke(type: type, socket_event: socket_event) do
          yield if block_given?
        end
      end

      def events_api(schema:, parsed_data:)
        if Events.config.print_tldr
          Events.logger.info { schema.tldr }
        end

        object = Events.config.listeners[schema.type.to_sym]
        if object
          safe_handler(type: schema.type.to_sym, object: object, schema: schema, parsed_data: parsed_data)
        end

        websocket.send("#{{ envelope_id: schema.envelope_id }.to_json}")
      end

      private

      def safe_handler(type:, object:, schema:, parsed_data:)
        Events.logger.info "Received Handler for #{type}"
        object[:handler].call(schema: schema, raw_data: parsed_data)
        object[:on_success]&.call(schema)
      rescue => error
        Events.logger.error("#{object[:handler]} returned #{error.class} => #{error.message}. Safely returning to websocket. #{error.backtrace[0...10]}")

        begin
          object[:on_failure]&.call(schema, error)
        rescue => on_failure_error
           Events.logger.error("Failure occured during on_failure block. #{on_failure_error}")
        end
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
        {
          'Authorization' => "Bearer #{SlackBot::Events.config.client_socket_token}"
        }
      end
    end
  end
end
