MAKEFLAGS += --silent

PROJECT_NAME = emailqueue

DOCKER_APACHE = emailqueue-apache
DOCKER_PHP = emailqueue-php
DOCKER_CRON = emailqueue-cron
DOCKER_DB = emailqueue-mysql

help: ## Show this help message
	echo 'usage: make [target]'
	echo
	echo 'targets:'
	egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

up: ## Start the containers
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml up -d

stop: ## Stop the containers
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml stop

down: ## Remove the containers
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml down

restart: ## Restart the containers
	$(MAKE) stop && $(MAKE) up

ps: ## Information about the containers
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml ps

apache-build: ## Builds the apache image
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml build emailqueue

apache-log: ## Tail the PHP error log
	docker logs -f --details ${DOCKER_APACHE}

apache-ssh: ## SSH into the apache container
	docker exec -it -u root ${DOCKER_APACHE} bash

db-build: ## Builds the mysql image
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml build emailqueue-mysql

db-log: ## Tail the MySQL error log
	docker logs -f --details ${DOCKER_DB}

db-ssh: ## SSH into the MySQL container
	docker exec -it -u root ${DOCKER_DB} bash

pull: ## Updates Emailqueue to the latest version
	docker exec -it -u root ${DOCKER_APACHE} git -C /var/www/BIRTHDAY_GOLD/emailqueue pull

delivery: ## Process the queue now instead of waiting for the next 1-minute interval. Emails that should be sent on the next Emailqueue call will be sent now.
	docker exec -it -u root ${DOCKER_APACHE} /var/www/BIRTHDAY_GOLD/emailqueue/scripts/delivery

purge: ## Purges the queue now instead of waiting for the next programmed purge
	docker exec -it -u root ${DOCKER_APACHE} /var/www/BIRTHDAY_GOLD/emailqueue/scripts/purge

flush: ## Removes all the emails in the queue. Use with care, will result in the loss of unsent enqueued emails.
	docker exec -it -u root ${DOCKER_APACHE} /var/www/BIRTHDAY_GOLD/emailqueue/scripts/flush

pause: ## Pauses email delivery. No emails will be sent under any circumstances.
	docker exec -it -u root ${DOCKER_APACHE} /var/www/BIRTHDAY_GOLD/emailqueue/scripts/pause

unpause: ## Unpauses email delivery. Emails will be sent.
	docker exec -it -u root ${DOCKER_APACHE} /var/www/BIRTHDAY_GOLD/emailqueue/scripts/unpause

config: ## Set up the configuration file
	./update_config.sh

install-docker: ## Install Docker
	@echo "Installing Docker..."
	@curl -fsSL https://get.docker.com -o get-docker.sh
	@sh get-docker.sh
	@rm get-docker.sh
	@echo "Installing Docker Compose..."
	@sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	@sudo chmod +x /usr/local/bin/docker-compose
	@sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	@echo "Docker and Docker Compose installed successfully."
