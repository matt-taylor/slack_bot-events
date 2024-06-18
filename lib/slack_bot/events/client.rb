# frozen_string_literal: true

require "eventmachine"
require "faraday"
require "faye/websocket"
require "pry"

module SlackBot
  module Events
    class Client
      BASE_API = "https://slack.com/api"

      def start!
        EM.run do
           websocket.on :open do |event|
            event_tracer(:open)
          end

          websocket.on :message do |event|
            event_tracer(:message) do
              parsed_data = JSON.parse(event.data)
              case parsed_data["type"]
              when "events_api"
                events_api(parsed_data)
              when "app_rate_limited"
                # https://api.slack.com/apis/rate-limits#events
                # Total allowed workspace events are 30,000 per hour
                # This message type is received once you have gone beyond that
                params = {
                  minute_rate_limited: parsed_data["minute_rate_limited"],
                  team_id: parsed_data["team_id"],
                  api_app_id: parsed_data["api_app_id"],
                }
                event_tracer("message:app_rate_limited", **params)
              when "hello"
                params = {
                  num_connections: parsed_data["num_connections"],
                  debug_info_host: parsed_data["debug_info"]["host"],
                  debug_info_connect_time: parsed_data["debug_info"]["approximate_connection_time"],
                }
                event_tracer("message:hello", **params)
              end
            end
          end

          websocket.on :close do |event|
            event_tracer(:close, code: event.code, reason: event.reason)
            @websocket = nil
          end
        end
      end

      def events_api(parsed_data)
        schematized = SlackBot::Events::Schemas::SocketPayload.new(parsed_data)
        Events.logger.info(schematized.tldr) if Events.config.print_tldr
        object = Events.config.listeners[schematized.type.to_sym]
        if object
          safe_handler(type: schematized.type.to_sym, object: object, schema: schematized, parsed_data: parsed_data)
        end
        websocket.send("#{{ envelope_id: schematized.envelope_id }.to_json}")
      end

      def event_tracer(type, **params)
        stringify = params.map { |k,v| "#{k}:#{v}" }.join("; ")
        Events.logger.info "[Event Received] #{type} #{stringify}"
        if block_given?
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          yield
          elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
          Events.logger.info "[Event completed] [#{elapsed_time.round(3)}s] #{type} #{stringify}"
        end
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
