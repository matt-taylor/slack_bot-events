# frozen_string_literal: true

module SlackBot
  module Events
    module Middleware
      class MessageHandler
        def call(schema:, websocket:, listener:, **params)
          if SlackBot::Events.config.acknowledge_on_receive?
            acknowledge!(websocket: websocket, schema: schema)
          end

          yield

          listener[:on_success]&.call(schema) if listener

          if SlackBot::Events.config.acknowledge_on_success? || SlackBot::Events.config.acknowledge_on_complete?
            acknowledge!(websocket: websocket, schema: schema)
          end
        rescue StandardError => error
          Events.logger.error do
            "#{listener[:handler]} returned #{error.class} => #{error.message}. #{error.backtrace[0...10]}"
          end

          begin
            listener[:on_failure]&.call(schema, error) if listener
          rescue StandardError => on_failure_error
             Events.logger.error("Failure occured during on_failure block. #{on_failure_error}")
          end

          if SlackBot::Events.config.acknowledge_on_complete?
            acknowledge!(websocket: websocket, schema: schema)
          elsif SlackBot::Events.config.acknowledge_on_success?
            Events.logger.debug do
              "Envelope acknowledgment skipped. Ackowledgment on success only. Slack may send a duplicate message"
            end
          end
        end

        private

        def acknowledge!(websocket:, schema:)
          return if schema.nil?

          websocket.send("#{{ envelope_id: schema.envelope_id }.to_json}")
          Events.logger.debug { "Envelope acknowledgment completed [#{SlackBot::Events.config.envelope_acknowledge}]" }
        end
      end
    end
  end
end
