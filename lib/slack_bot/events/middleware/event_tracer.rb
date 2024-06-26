# frozen_string_literal: true

module SlackBot
  module Events
    module Middleware
      class EventTracer
        def call(type:, socket_event:, schema: nil, parsed_data: nil, **params)
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          temp_type = type.dup.to_s
          case type
          when :close
            additional_info = "code: #{socket_event.code} reason:#{socket_event.reason}"
          when :message

            case parsed_data.dig("type")
            when "app_rate_limited"
              # https://api.slack.com/apis/rate-limits#events
              # Total allowed workspace events are 30,000 per hour
              # This message type is received once you have gone beyond that
              temp_type += ":#{parsed_data.dig("type")}"
              additional_info = "minute_rate_limited:#{parsed_data["minute_rate_limited"]} " \
                "team_id:#{parsed_data["team_id"]} " \
                "api_app_id:#{parsed_data["api_app_id"]}"
            else
              accurate_type = parsed_data.dig("payload","event","subtype") || parsed_data.dig("payload","event","type")
              p_type = [
                parsed_data.dig("type"),
                accurate_type
              ].compact.join(":")

              # Expected other types are `events_api` and `hello`
              temp_type += ":#{p_type}"
            end
          end

          Events.logger.info { "[Event Received] #{temp_type} #{additional_info}" }

          yield

          elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
          Events.logger.info { "[Event Finished] #{temp_type} [#{(elapsed_time * 1000).round(2)}ms]" }
        end
      end
    end
  end
end
