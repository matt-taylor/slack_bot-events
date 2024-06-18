# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

module SlackBot
  module Events
    module Schemas
      module Type
        class BotProfile < JsonSchematize::Generator
          schema_default option: :dig_type, value: :string

          add_field name: :id, type: String
          add_field name: :app_id, type: String
          add_field name: :name, type: String
          add_field name: :deleted, type: JsonSchematize::Boolean
          add_field name: :updated, type: String
          add_field name: :team_id, type: String
        end
      end
    end
  end
end
