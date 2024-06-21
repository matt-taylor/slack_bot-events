# frozen_string_literal: true

require "slack_bot/events/middleware/event_tracer"
require "slack_bot/events/middleware/message_handler"

####################
#
# Adapted from Sidekiq:
# https://github.com/sidekiq/sidekiq/blob/main/lib/sidekiq/middleware/chain.rb
#
####################

module SlackBot
  module Events
    module Middleware
      class Chain
        include Enumerable

        attr_reader :type

        DEFAULT_ENTRIES = {
          message: [Middleware::EventTracer, Middleware::MessageHandler],
          open: [Middleware::EventTracer],
          close: [Middleware::EventTracer],
        }

        def initialize(type:)
          @type = type
        end

        def self.default_entry(type)
          DEFAULT_ENTRIES[type].map { Entry.new(_1) }
        end

        def entries
          @entries ||= self.class.default_entry(type)
        end

        def remove(klass)
          raise ArgumentError, "Unable to remove default Middleware #{klass}" if self.class.default_entry.map(:klass).include?(klass)

          entries.delete_if { |entry| entry.klass == klass }
        end

        def add(klass, *args)
          remove(klass)
          entries << Entry.new(klass, args)
        end

        def prepend(klass, *args)
          remove(klass)
          entries.insert(0, Entry.new(klass, args))
        end

        def insert_before(oldklass, newklass, *args)
          i = entries.index { |entry| entry.klass == newklass }
          new_entry = i.nil? ? Entry.new(klass, args) : entries.delete_at(i)
          i = entries.index { |entry| entry.klass == oldklass } || 0
          entries.insert(i, new_entry)
        end

        def insert_after(oldklass, newklass, *args)
          i = entries.index { |entry| entry.klass == newklass }
          new_entry = i.nil? ? Entry.new(klass, args) : entries.delete_at(i)
          i = entries.index { |entry| entry.klass == oldklass } || entries.count - 1
          entries.insert(i + 1, new_entry)
        end

        def exists?(klass)
          any? { |entry| entry.klass == klass }
        end

        def empty?
          entries.nil? || entries.empty?
        end

        def retrieve
          map(&:instance!)
        end

        def each(&block)
          entries.each(&block)
        end

        def clear
          @entries = nil
        end

        def invoke_message(type:, socket_event:, parsed_data:, websocket:, listener:, schema: nil)
          return yield if empty?

          chain = retrieve
          traverse_chain = proc do
            if chain.empty?
              yield
            else
              params = {
                parsed_data: parsed_data,
                schema: schema,
                socket_event: socket_event,
                listener: listener,
                type: type,
                websocket: websocket,
              }
              chain.shift.call(**params, &traverse_chain)
            end
          end
          traverse_chain.call
        end

        def invoke(type:, socket_event:)
          return yield if empty?

          chain = retrieve
          traverse_chain = proc do
            if chain.empty?
              yield
            else
              chain.shift.call(type: type, socket_event: socket_event, &traverse_chain)
            end
          end
          traverse_chain.call
        end

        def inspect_me
          entries.map do |e|
            [
              e.klass,
              e.args
            ]
          end
        end
      end

      class Entry
        attr_reader :klass
        attr_reader :args

        def initialize(klass, args = [])
          @klass = klass
          @args = args
        end

        def instance!
          klass.new(*args)
        end
      end
    end
  end
end
