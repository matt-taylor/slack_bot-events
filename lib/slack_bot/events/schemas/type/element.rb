# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

require "slack_bot/events/schemas/type/item"

module SlackBot
  module Events
    module Schemas
      module Type
        class Element < JsonSchematize::Generator
          schema_default option: :dig_type, value: :string

          add_field name: :type, type: String
          add_field name: :elements, type: SlackBot::Events::Schemas::Type::Element, array_of_types: true, required: false
          add_field name: :text, type: String, required: false
        end
      end
    end
  end
end
