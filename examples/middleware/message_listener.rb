# frozen_string_literal: true

module MessageListener
  def self.call(schema:, raw_data:)
    # Do some cool(quick returning) things here
    # schema.payload.event will be a SlackBot::Events::Schemas::Type::Message
    puts "Heya! I found a message! #{schema.payload.event.text}"
    raise StandardError, "I Randomly decided to Barf" if rand > 0.9
  end

  def self.on_success(schema)
    # Send a metric maybe?
    # Or a Log Message
    puts "Congrats! You executed it succesfully"
  end

  def self.on_failure(schema, error)
    # Send job to sidekiq to try again?
    # Or send a log message; but make sure to do it quick
    puts "Yikes, You died a misreable death"
  end
end
