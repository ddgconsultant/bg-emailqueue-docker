MAKEFLAGS += --silent

PROJECT_NAME = emailqueue

DOCKER_APACHE = emailqueue-apache
DOCKER_PHP = emailqueue-php
DOCKER_CRON = emailqueue-cron
DOCKER_DB = emailqueue-mariadb

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
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml build apache

apache-log: ## Tail the PHP error log
	docker logs -f --details ${DOCKER_APACHE}

apache-ssh: ## SSH into the apache container
	docker exec -it -u root ${DOCKER_APACHE} bash

cron-build: ## Builds the cron image
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml build cron

cron-ssh: ## SSH into into the cron container
	docker exec -it -u root ${DOCKER_CRON} bash

cron-log: ## Tail the cron error log
	docker logs -f --details ${DOCKER_CRON}

cron-restart: ## Restarts the cron container
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml restart cron

db-build: ## Builds the mariadb image
	docker-compose -p ${PROJECT_NAME} --file docker/docker-compose.yml build mariadb

db-log: ## Tail the PHP error log
	docker logs -f --details ${DOCKER_DB}

db-ssh: ## SSH into the MariaDB container
	docker exec -it -u root ${DOCKER_DB} bash

pull: ## Updates Emailqueue to the latest version
	docker exec -it -u root ${DOCKER_APACHE} git -C /emailqueue pull

delivery: ## Process the queue now instead of waiting for the next 1-minute interval
	docker exec -it -u root ${DOCKER_APACHE} php -q /emailqueue/scripts/delivery

purge: ## Purges the queue now instead of waiting for the next programmed purge
	docker exec -it -u root ${DOCKER_APACHE} php -q /emailqueue/scripts/purge