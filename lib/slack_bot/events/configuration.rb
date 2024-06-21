# frozen_string_literal: true

require "class_composer"
require "logger"
require "slack_bot/events/middleware/chain"

module SlackBot
  module Events
    class Configuration
      include ClassComposer::Generator

      ALLOWED_ACKNOWLEDGE = [
        DEFAULT_ACKNOWLEDGE = :on_complete,
        :on_success,
        :on_receive,
      ]

      add_composer :client_socket_token, allowed: String, default: ENV["SLACK_SOCKET_TOKEN"]
      add_composer :print_tldr, allowed: [true.class, false.class], default: true
      add_composer :message_middleware, allowed: Middleware::Chain, default: Middleware::Chain.new(type: :message)
      add_composer :open_middleware, allowed: Middleware::Chain, default: Middleware::Chain.new(type: :open)
      add_composer :close_middleware, allowed: Middleware::Chain, default: Middleware::Chain.new(type: :close)
      add_composer :envelope_acknowledge, allowed: Symbol, default: DEFAULT_ACKNOWLEDGE, validator: ->(val) { ALLOWED_ACKNOWLEDGE.include?(val) }, invalid_message: ->(_) { "Must by a Symbol in #{ALLOWED_ACKNOWLEDGE}" }

      ALLOWED_ACKNOWLEDGE.each do |ack|
        define_method :"acknowledge_#{ack}?" do
          envelope_acknowledge == ack
        end
      end

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
