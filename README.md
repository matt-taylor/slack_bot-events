# SlackBot::Events

Zappier is a workflow engine that you have to pay for. Welcome to SlackBot::Events, a free alternative to Zappier.

SlackBot::Events allows you to listen to events from your paid Slack workspace and run automated code based on real time events. You can run automations based on events like: Message Deleted, Reactions Added, Reactions Removed, Message sent to channel, Message sent to Thread, User added to Channel, and so many more. [View Full list of Events Here](https://api.slack.com/events)


## Configuration
### Slack Bot Requirements:
SlackBot::Events gem utilizes the [Slack Events API](https://api.slack.com/apis/events-api) with Socket Mode. Events are pushed directly to any socket that is open and accepting requets.

**Warning** This Slack Bot requires the ability to connect to the events API using a WebSocket. This is only available in paid workspaces and development workspaces. Not available in free Workspaces.

You will need:
#### Slack App created
To create a Slack App, checkout out [Slacks App Quickstart Guide](https://api.slack.com/quickstart). If you are familiar with Slack App Creation, you can go directly to the [Slack Apps Homepage](https://api.slack.com/apps)

#### Slack App Socket Enable
SlackBot::Events is based on Socket mode. Socket mode must get enabled before you can subscribe to events without a `Request URL` public endpoint in your application.

Navigate to your app and select the `Socket Mode` tab on the left. Ensure the switch to `Enable Socket Mode` is toggled on before proceeding

You will be asked to create a new token. Name it whatever you would like. This will create a new token for you.

You will **NEED** to retain the token for this Gem. (But don't worry, you can create a new one using with [Slack App Level tokens](https://api.slack.com/concepts/token-types#app-level) later as well)

#### Slack App Events received
Every workpace has a limitation on the number of events the entire workspace can receive. This means that you should choose carefully which events your App can recieve.

Navigate to your app and select the `Event Subscriptions` tab on the left.

Carefully pick the events to subscribe to under the `Subscribe to bot events`.

A good place to start is by subscribing to the following events:
```
message.channels
reaction_added
reaction_removed
```
*Note*: This will automatically add the correct OAuth permissions to the bot user. When you want to add additional subscriptions, come back here.

#### Install the Slack app to your workspace
Navigate to your app and select the `Install App` tab on the left. Click on `Install to Workspace`. In some cases, you may need to get Workspace Admin approval before the app becomes available in the workspace.

#### Add the Bot to specific Channels
Once the App is intalled into the workspace, invite the new bot to channels. Once the bot is in a channel, it will have the ability to send subscribed events to SlackBot::Events gem

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
  # => on_success: Acknowledge only on succesful listener events (Use with caution)
  # => on_receive: Acknowledge at the beginning of the middleware chain before it gets to listener events
  # Default value: :on_complete
  config.envelope_acknowledge = :on_complete
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
