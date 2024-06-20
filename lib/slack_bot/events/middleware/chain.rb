# frozen_string_literal: true

require "slack_bot/events/middleware/event_tracer"

module SlackBot
  module Events
    module Middleware
      class Chain
        include Enumerable

        def self.default_entry
          [
            Entry.new(Middleware::EventTracer),
          ]
        end

        def entries
          @entries ||= self.class.default_entry
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

        def invoke_message(type:, socket_event:, parsed_data:, schema: nil)
          return yield if empty?

          chain = retrieve
          traverse_chain = proc do
            if chain.empty?
              yield(yield: schema, parsed_data: parsed_data)
            else
              chain.shift.call(type: type, socket_event: socket_event, schema: schema, parsed_data: parsed_data, &traverse_chain)
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
