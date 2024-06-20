# frozen_string_literal: true

module SlackBot
  module Events
    module Schematize
      def self.message(parsed_data)
        case parsed_data["type"]
        when "events_api"
          return SlackBot::Events::Schemas::SocketPayload
        when "app_rate_limited"
        when "hello"
        end
      end

      def self.call(data:)
        parsed_data = JSON.parse(data)
        return { parsed_data: parsed_data } unless schema_klass = message(parsed_data)

        if schema_klass.respond_to?(:call)
          { schema: schema_klass.call(parsed_data).new(parsed_data), parsed_data: parsed_data }
        else
          { schema: schema_klass.new(parsed_data), parsed_data: parsed_data }
        end
      end
    end
  end
end
