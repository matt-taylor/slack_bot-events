FROM ruby:3.2.3

WORKDIR /gem
COPY Gemfile /gem/Gemfile

COPY slack_bot-events.gemspec /gem/slack_bot-events.gemspec
COPY lib/slack_bot/events/version.rb /gem/lib/slack_bot/events/version.rb

RUN gem update --system
RUN gem install bundler

COPY . /gem

