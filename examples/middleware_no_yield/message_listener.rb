# frozen_string_literal: true

module MessageListener

  def self.call(schema:, raw_data:)
    raise "Its okay, It never actually makes it here"
  end

  def self.on_success(schema)
    # Send a metric maybe?
    # Or a Log Message
    puts "I did still make it to the on_success handler"
  end

  def self.on_failure(schema, error)
    # Send job to sidekiq to try again?
    # Or send a log message; but make sure to do it quick
    puts "Yikes, You died a misreable death"
  end
end
