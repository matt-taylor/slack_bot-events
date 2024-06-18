# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

require "slack_bot/events/schemas/data_payload"

module SlackBot
  module Events
    module Schemas
      class SocketPayload < JsonSchematize::Generator
        schema_default option: :dig_type, value: :string

        add_field name: :envelope_id, type: String

        add_field name: :payload, type: SlackBot::Events::Schemas::DataPayload

        add_field name: :type, type: String
        add_field name: :accepts_response_payload, type: JsonSchematize::Boolean
        add_field name: :retry_attempt, type: Integer
        add_field name: :retry_reason, type: String


        def type
          payload.event.type
        end

        def tldr
          retry_language = "#{retry_attempt}"
          retry_language += ":#{retry_reason}" if retry_attempt > 0
          "tldr:#{payload.event.tldr}; retry:#{retry_language}"
        end
      end
    end
  end
end
