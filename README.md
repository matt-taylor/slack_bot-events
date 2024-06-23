# SlackBot Events

Welcome to SlackBot Events Gem! This gem provides a seamless way to hook into your paid Slack Workspace's Events API and run complex or simple automation. You can run automations based on events like: Message Deleted, Reactions Added, Reactions Removed, Message sent to channel, Message sent to Thread, User added to Channel, and so many more. [View Full list of Events Here](https://api.slack.com/events).

SlackBot Events provides the foundational tooling to run a SlackBot, automate Jira tickets based on Events, Customize and Automate AI responses to messages, Automate tagging relavant groups in threads, track time to respond and time to resolve threads, and so much more.

SlackBot Events Gem connects directly into your paid Slack workspace by utilizing websockets. Websockets provides a resilient, safe, and reliable connection to retreive events without the need to expose a public endpoint for Slack Events.


## SlackBot Events inspiration

There already exists No to Low code Slack workflow Engines like Zappier. However, these workflows are often slow and buggy. They cost money based on usage. Additionally, creating complex workflows with low code is a bit messy.

SlackBot Events provides a free alternative to exposing events from your paid Slack Workspace.

## Configuration

### Required Slack Bot Configuration
This bit is rather boring. Check out the [Boring Slack Configuration Setup](/boring_slack_configuration.md). You will need the App Level Token for the next step

### Required ENV variables:
`SLACK_SOCKET_TOKEN` is the only ENV variable that is required for this Gem. Using the token that was saved from an earlier step, set the token to the ENV variable `SLACK_SOCKET_TOKEN`. There is an alternate assignment option below.

### Configuration Options:
``` ruby
SlackBot::Events.configure do |config|
  # This token is needed to retreive a WebSocket connection to the Events API
  # Default value: ENV["SLACK_SOCKET_TOKEN"]
  config.client_socket_token = "AppLevelToken"

  # By default, SlackBot::Events will print out a TLDR of every events message that comes through
  # Default value: true
  config.print_tldr = true

  # By default, SlackBot::Events will acknowledge at the end of the middleware chain after it passes the message to the event listener. Available options:
  # => on_complete: Acknowledge after listener has completed on failure and on success
  # => on_success: Acknowledge only on succesful listener events (Use with caution)
  # => on_receive: Acknowledge at the beginning of the middleware chain before it gets to listener events
  # Default value: :on_complete
  config.envelope_acknowledge = :on_complete

  # By default, this gem outputs to STDOUT. You can set your own logger ot set it to the Rails logger if desired
  # Default value: Logger.new(STDOUT)
  config.logger = Rails.logger
end
```

### Event Listeners:
Event Listeners is where the configurable power comes in. Listeners are custom code that gets run on specific event_api actions as defined in [Slack Event Types](https://api.slack.com/events).

There can be at most configured listener listeing to any given event type.

To Register a new listener:
```ruby
SlackBot::Events.register_listener(name: "event_type_name", handler: handler_object)
SlackBot::Events.register_listener(name: "event_type_name_2", handler: handler_object2, on_success: on_success_proc)
SlackBot::Events.register_listener(name: "event_type_name_3", handler: handler_object3, on_failure: on_failure_proc)
```

#### Handler
The Handler argument must be an object that responds to `call` with KWargs `schema` and `raw_data`.

#### On Failure
The `on_failure` argument must be an object that resoonds to `call` with 2 arguments. The first argument will be the converted schema if available. The second argument will be the error that caused the Handler to fail

#### On Success
The `on_success` argument must be an object that resoonds to `call` with 1 argument. The argument will be the converted schema if available.

[Example with Basic Listeners](/examples/basic)

[Example with Multiple Listeners](/examples/multi_listener)

## Installation

## Known Restrictions
### Limited number of events per hour per workspace
[Slack Events API](https://api.slack.com/apis/rate-limits#events) has a limit of 30,000 events sent per hour per workspace. When this limit is hit, Slack will send the message type `app_rate_limited`.

You can see an example of how this can get handled in the [EventTracer Middleware](lib/slack_bot/events/middleware/event_tracer.rb)


### 10 open Sockets per App
A Slack app can have at most 10 open sockets to Slack simultaneously. On WebSocket aquisition, it will first send the `open` type. This will reveal how many open connections there currently are.

In regards to SlackBot::Events, this limitation means that you can have at most 10 instances of SlackBot::Events running per bod.

For more information, Visit [Using Multiple Connections](https://api.slack.com/apis/socket-mode#connections) on Slack API page

### Message Acknowledgment
`SlackBot::Events` by default will handle message acknowledgment on your behalf. This can get taken care of before or after the handler is executed.

Slack expects an Aknowledgment within 3 seconds. If your Middleware combined with the handler execution takes longer than the expected 3 seconds, Slack will immediately attempt to send the same envelope package again. This will cause duplication in your application.

Retry attempts can occur on any open socket.
- Attempt 3 Seconds after no response
- Attempt 60 Seconds after no response
- Attempt 5 minutes after no response

Over the course of an hour, if you fail to send acknowledgement before the first retry, you will be rate limited and your app cordoned off

Ideally, your listener executes quickly and returns. This means your execution is quick or you ship the data off to an async job like Sidekiq or spawn a new thread.
