# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

module SlackBot
  module Events
    module Schemas
      module Type
        class Item < JsonSchematize::Generator
          schema_default option: :dig_type, value: :string

          add_field name: :type, type: String
          add_field name: :channel, type: String
          add_field name: :ts, type: String
        end
      end
    end
  end
end
