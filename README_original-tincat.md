# README for Birthday.Gold Email Queue Docker Setup

This repository contains the Dockerized email queue system customized for Birthday.Gold's requirements. Follow the instructions below to set up and configure the system within our environment.

---

## Prerequisites

Ensure the following prerequisites are met before starting:

- **Operating System:** Ubuntu 24
- **Login:** Access the server as `root`

## Setup Instructions

### Step 1: Install Required Tools
Run the following commands to install Docker, Docker Compose, and Make:

```bash
apt update && apt upgrade -y
apt install -y curl git make

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

### Step 2: Clone the Repository

```bash
mkdir -p /opt/birthdaygold/emailqueue
cd /opt/birthdaygold/emailqueue
git clone https://github.com/ddgconsultant/bg-emailqueue-docker.git
cd bg-emailqueue-docker
```

### Step 3: Configure Application Settings
Copy the example configuration file and edit it with the provided credentials:

```bash
cp application.config.inc.php.example application.config.inc.php
```

Use `scp` to download the `BG_ENV_PASSWORD.txt` file from the FTP server:

```bash
scp richard@ftp.birthday.gold:/BG_ENV_PASSWORD.txt ./
```

Extract the required passwords and update the configuration file using `sed`:

```bash
source BG_ENV_PASSWORD.txt

sed -i "s|YOUR_API_KEY|$API_KEY|g" application.config.inc.php
sed -i "s|YOUR_SMTP_PASSWORD|$SMTP_PASSWORD|g" application.config.inc.php
```

Ensure other required fields in the configuration file are updated according to your environment.

### Step 4: Start the Services
Bring up the Docker services using Make:

```bash
make up
```

This will build the Docker images and start the Email Queue system. It may take a few minutes on the first run.

### Step 5: Verify Installation
- Access the monitoring frontend at:
  
  ```
  http://[your_server_ip]:8081/frontend/
  ```

- Test the API:
  
  ```
  http://[your_server_ip]:8081/test.php
  ```

### Step 6: Manage Services
Use the provided Make commands to manage the system:

```bash
make stop       # Stop the containers
make restart    # Restart the containers
make delivery   # Force email delivery
make pause      # Pause email delivery
make unpause    # Unpause email delivery
make flush      # Flush the queue (use with caution)
```

---

## Reference

For additional information about the original project, see the `README_original.md` file in this repository.

---

# License
This project is customized for internal use at Birthday.Gold and adheres to the original licensing terms as specified in the source repository.
