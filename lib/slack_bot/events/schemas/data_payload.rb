# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

require "slack_bot/events/schemas/authorization"
require "slack_bot/events/schemas/type/base"
require "slack_bot/events/schemas/type/reaction_modified"
require "slack_bot/events/schemas/type/message"

module SlackBot
  module Events
    module Schemas
      class DataPayload < JsonSchematize::Generator
        schema_default option: :dig_type, value: :string

        ALLOWED_EVENT_TYPES = [
          SlackBot::Events::Schemas::Type::ReactionModified,
          SlackBot::Events::Schemas::Type::Message,
          SlackBot::Events::Schemas::Type::Base,
        ]

        add_field name: :token, type: String
        add_field name: :team_id, type: String
        add_field name: :context_team_id, type: String, required: false
        add_field name: :api_app_id, type: String, required: false

        add_field name: :event, type: ALLOWED_EVENT_TYPES.first, types: ALLOWED_EVENT_TYPES, converter: ->(data) { DataPayload.event_type(data) }

        add_field name: :type, type: String, required: false
        add_field name: :event_id, type: String, required: false
        add_field name: :event_time, type: Integer

        add_field name: :authorizations, type: SlackBot::Events::Schemas::Authorization, array_of_types: true

        add_field name: :is_ext_shared_channel, type: JsonSchematize::Boolean
        add_field name: :event_context, type: String

        def self.event_type(payload)
          case payload["type"]
          when "reaction_removed", "reaction_added"
            SlackBot::Events::Schemas::Type::ReactionModified.new(payload)
          when "message"
            case payload["subtype"]
            when nil
              SlackBot::Events::Schemas::Type::Message.new(payload)
            when "message_changed", "message_deleted"
              SlackBot::Events::Schemas::Type::Base.new(payload.merge("tldr" => "subtype: #{payload["subtype"]}"))
            else
              # messages that were changed can be considered, but not at this time
              SlackBot::Events::Schemas::Type::Base.new(payload)
            end
          else
            # When the event type does not exist yet; dont fret, give it the bare bones base objet that delegates
            SlackBot::Events::Schemas::Type::Base.new(payload)
          end
        end

      end
    end
  end
end
