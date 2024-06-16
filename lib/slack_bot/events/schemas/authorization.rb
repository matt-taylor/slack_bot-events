# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

module SlackBot
  module Events
    module Schemas
      class Authorization  < JsonSchematize::Generator
        schema_default option: :dig_type, value: :string

        add_field name: :enterprise_id, type: String, required: false
        add_field name: :team_id, type: String
        add_field name: :user_id, type: String
        add_field name: :is_bot, type: JsonSchematize::Boolean
        add_field name: :is_enterprise_install, type: JsonSchematize::Boolean
      end
    end
  end
end
