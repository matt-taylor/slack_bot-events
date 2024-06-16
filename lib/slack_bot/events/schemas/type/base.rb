# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

module SlackBot
  module Events
    module Schemas
      module Type
        class Base < JsonSchematize::Generator
          schema_default option: :dig_type, value: :string

          add_field name: :tldr, type: String, required: false

          def tldr
            if @tldr
              "type: #{type}; #{@tldr}"
            else
              "type: #{type}; unknown;"
            end
          end

          def method_missing(m, *args, &block)
            if __raw_params.has_key?(m.to_s)
              return __raw_params[m.to_s]
            end

            super
          end
        end
      end
    end
  end
end
