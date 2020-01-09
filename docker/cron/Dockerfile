FROM debian:latest

#Install cron
RUN apt-get update && apt-get -y install cron

# Add crontab file in the cron directory
ADD cron/cronjobs /etc/cron.d/cronjobs

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/cronjobs

# Add crontab
RUN crontab /etc/cron.d/cronjobs

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Install docker so we can run commands on other containers using docker exec, this is why we map /var/run/docker.sock:/var/run/docker.sock on docker-compose
RUN apt-get update && apt-get -y install docker.io

# Run the command on container startup
CMD ["cron", "-f"]