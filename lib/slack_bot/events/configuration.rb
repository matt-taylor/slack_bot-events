# frozen_string_literal: true

require "class_composer"

module SlackBot
  module Events
    class Configuration
      include ClassComposer::Generator
      add_composer :client_id, allowed: String, default: ENV["SLACK_CLIENT_ID"]
      add_composer :client_secret, allowed: String, default: ENV["SLACK_CLIENT_SECRET"]
      add_composer :client_signing_secret, allowed: String, default: ENV["SLACK_SIGNING_SECRET"]
      add_composer :client_socket_token, allowed: String, default: ENV["SLACK_SOCKET_TOKEN"]
      add_composer :client_verification_token, allowed: String, default: ENV["SLACK_VERIFICATION_TOKEN"]

      def register_listener(name:, handler:)
        @listeners ||= {}

        if @listeners.has_key(name.to_sym)
        end

        @listeners[name] = handler

        true
      end

      def remove_listener(name:)
        @listeners ||= {}


      end
    end
  end
end
