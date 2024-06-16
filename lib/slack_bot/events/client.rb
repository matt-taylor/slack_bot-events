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
            p [:open]
          end

          websocket.on :message do |event|
            parsed_data = JSON.parse(event.data)
            if parsed_data["type"] == "events_api"
              puts parsed_data.to_json
              item = SlackBot::Events::Schemas::SocketPayload.new(parsed_data)
              s = {
                type: item.payload.event.type,
                tldr: item.payload.event.tldr,
              }
              puts s
              websocket.send("#{{ envelope_id: item.envelope_id }.to_json}")
            else
              puts event.data
            end
          end

          websocket.on :close do |event|
            p [:close, event.code, event.reason]
            @websocket = nil
          end
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
