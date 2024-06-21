# Slack Bot Requirements:
SlackBot::Events gem utilizes the [Slack Events API](https://api.slack.com/apis/events-api) with Socket Mode. Events are pushed directly to any socket that is open and accepting requets.

**Warning** This Slack Bot requires the ability to connect to the events API using a WebSocket. This is only available in paid workspaces and development workspaces. Not available in free Workspaces.

You will need:
## Slack App created
To create a Slack App, checkout out [Slacks App Quickstart Guide](https://api.slack.com/quickstart). If you are familiar with Slack App Creation, you can go directly to the [Slack Apps Homepage](https://api.slack.com/apps)

## Slack App Socket Enable
SlackBot::Events is based on Socket mode. Socket mode must get enabled before you can subscribe to events without a `Request URL` public endpoint in your application.

Navigate to your app and select the `Socket Mode` tab on the left. Ensure the switch to `Enable Socket Mode` is toggled on before proceeding

You will be asked to create a new token. Name it whatever you would like. This will create a new token for you.

You will **NEED** to retain the token for this Gem. (But don't worry, you can create a new one using with [Slack App Level tokens](https://api.slack.com/concepts/token-types#app-level) later as well)

## Slack App Events received
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

## Install the Slack app to your workspace
Navigate to your app and select the `Install App` tab on the left. Click on `Install to Workspace`. In some cases, you may need to get Workspace Admin approval before the app becomes available in the workspace.

## Add the Bot to specific Channels
Once the App is intalled into the workspace, invite the new bot to channels. Once the bot is in a channel, it will have the ability to send subscribed events to SlackBot::Events gem

