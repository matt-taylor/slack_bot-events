# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require "slack_bot/events/version"
circle_ci_build = ENV['CIRCLECI'] == 'true'
pre_release_tag = ENV["CIRCLE_TAG"]&.match?(/^pre-.*/)
gets_pre_release_version = circle_ci_build && pre_release_tag

patch_level = gets_pre_release_version ? ".99.pre.#{ENV.fetch('CIRCLE_BUILD_NUM', '')}" : ""

Gem::Specification.new do |spec|
  spec.name    = "slack_bot-events"
  spec.version = SlackBot::Events::VERSION + patch_level
  spec.authors = ["Matt Taylor"]
  spec.email   = ["mattius.taylor@gmail.com"]

  spec.summary     = "Slack Events API is here! Receive events without making a public endpoint. This Gem taps into the Events Websocket Architecture"
  spec.description = "Describe the gem here"
  spec.homepage    = "https://github.com/matt-taylor/slack_bot-events"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.1")

  spec.metadata = {
    "github_repo" => spec.homepage,
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "json_schematize"
  spec.add_dependency "class_composer", "~> 1.0"
  spec.add_dependency "faye-websocket"

  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov"
end
