# frozen_string_literal: true

require "json_schematize"
require "json_schematize/generator"

require "slack_bot/events/schemas/type/block"
require "slack_bot/events/schemas/type/bot_profile"

module SlackBot
  module Events
    module Schemas
      module Type
        class Message < JsonSchematize::Generator
          schema_default option: :dig_type, value: :string

          add_field name: :type, type: String
          add_field name: :user, type: String
          add_field name: :ts, type: String
          add_field name: :client_msg_id, type: String
          add_field name: :text, type: String
          add_field name: :team, type: String

          add_field name: :blocks, type: SlackBot::Events::Schemas::Type::Block, array_of_types: true
          add_field name: :bot_profile, type: SlackBot::Events::Schemas::Type::BotProfile, required: false

          add_field name: :thread_ts, type: String, required: false
          add_field name: :parent_user_id, type: String, required: false

          add_field name: :channel, type: String
          add_field name: :event_ts, type: String
          add_field name: :channel_type, type: String

          def made_from_user?
            bot_profile.nil? || JsonSchematize::EmptyValue === bot_profile
          end

          def made_from_bot?
            !made_from_user?
          end

          def tldr
            "type:#{type}; user:#{user}; channel:#{channel}; ts_id:#{combined_id}"
          end

          def thread_ts
            return_nil?(@thread_ts) ? nil : @thread_ts
          end

          def parent_user_id
            return_nil?(@parent_user_id) ? nil : @parent_user_id
          end

          private

          def combined_id
            thread_ts ? "#{ts}:#{thread_ts}" : ts
          end

          def return_nil?(val)
            JsonSchematize::EmptyValue === val || val.nil?
          end
        end
      end
    end
  end
end
