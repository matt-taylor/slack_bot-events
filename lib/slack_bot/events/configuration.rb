# frozen_string_literal: true

require "class_composer"
require "logger"

module SlackBot
  module Events
    class Configuration
      include ClassComposer::Generator
      add_composer :client_id, allowed: String, default: ENV["SLACK_CLIENT_ID"]
      add_composer :client_secret, allowed: String, default: ENV["SLACK_CLIENT_SECRET"]
      add_composer :client_signing_secret, allowed: String, default: ENV["SLACK_SIGNING_SECRET"]
      add_composer :client_socket_token, allowed: String, default: ENV["SLACK_SOCKET_TOKEN"]
      add_composer :client_verification_token, allowed: String, default: ENV["SLACK_VERIFICATION_TOKEN"]
      add_composer :print_tldr, allowed: [true.class, false.class], default: true

      def register_listener(name:, handler:, on_success: nil, on_failure: nil)
        if event_handler = listeners[name.to_sym]
          logger.warn "`#{name}` already exists as listener event. Reseting with new input"
        end

        validate_listener!(handler: handler, on_success: on_success, on_failure: on_failure)

        listeners[name.to_sym] = { handler: handler, name: name, on_success: on_success, on_failure: on_failure }
        true
      end

      def remove_listener(name:)
        listeners ||= {}
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def logger=(log)
        @logger = log
      end

      def listeners
        @listeners ||= {}
      end

      private

      def validate_listener!(handler:, on_success:, on_failure:)
        unless retreive_method(object: handler, meth_name: :call)
          raise ArgumentError, "When present, handler argument needs to respond_to :call with schema: and raw_data: kwargs"
        end

        if on_success
          unless retreive_method(object: on_success, meth_name: :call)
            raise ArgumentError, "When present, on_success argument needs to respond_to :call with 1 arguments passed in"
          end
        end

        if on_failure
          unless retreive_method(object: on_failure, meth_name: :call)
            raise ArgumentError, "When present, on_failure argument needs to respond_to :call with 2 arguments passed in"
          end
        end
      end

      def retreive_method(object:, meth_name:)
        object.method(meth_name.to_sym)
      rescue NameError
        nil
      end
    end
  end
end
