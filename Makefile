.PHONY: help bash build bundle rspec rubocop rubocop-todo

GEM=slack_bot-events
DC_FILE?=docker-compose.yml
FILES?=.

help: #: Show help topics
	@grep "#:" Makefile | grep -v "@grep" | sed "s/.*:\([A-Za-z_ -]*\):.*#\(.*\)/$$(tput setaf 3)\1$$(tput sgr0)\2/g" | sort

bash: #: Get a bash prompt on your service container
	@touch .bash_history
	docker-compose -f $(DC_FILE) run $(GEM) bash

build: #: Build the containers that we'll need
	docker-compose -f $(DC_FILE) build --pull

rspec: #: Run RSPEC, set TEST_FILE to run a specific file
	docker-compose -f $(DC_FILE) run --rm -e RAILS_ENV=test $(GEM) bundle exec rspec --fail-fast $(FILES)
