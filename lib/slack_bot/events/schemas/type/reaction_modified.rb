# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

require "slack_bot/events/schemas/type/item"

module SlackBot
  module Events
    module Schemas
      module Type
        class ReactionModified < JsonSchematize::Generator
          schema_default option: :dig_type, value: :string

          add_field name: :type, type: String
          add_field name: :user, type: String
          add_field name: :reaction, type: String
          add_field name: :item, type: SlackBot::Events::Schemas::Type::Item
          add_field name: :item_user, type: String
          add_field name: :event_ts, type: String

          def channel
            item.channel
          end

          def tldr
            "type: #{type}; channel:#{channel}; reaction:#{reaction}"
          end
        end
      end
    end
  end
end
