# Firefly III Quickstart Docker Image

Welcome to the Firefly III Quickstart Docker Image repository! This custom Docker image is optimized to simplify and accelerate the deployment of Firefly III, the free and open-source personal finance manager. This image automates much of the setup process, allowing users to get Firefly III up and running with minimal manual configuration.


## Key Features
- **Automated Environment Setup**: Automatically fetches and configures .env and .db.env files from official sources to ensure your environment is correctly set up.
- **Simplified Configuration**: Pre-configured with essential settings to start the application, only requiring minimal adjustments for personalization.
- **Docker Compose Support**: Includes a Docker Compose file for easy deployment and management of services related to Firefly III.


## Quickstart Guide

### Pull the Docker Image

```bash
docker pull nicxx2/fireflyiii-quickstart
```

***Run with Docker Compose*** </br>
Use the Docker Compose from the repository, make any necessary adjustments to the environment variables, and start your services:

```bash
docker-compose up -d
```
This command will set up Firefly III along with its necessary services like database and scheduled tasks.

***Access Firefly III*** <br>
Open your web browser and access Firefly III at http://localhost:8081.

### Configuration
Modify the provided Docker Compose file to customize the environment variables as per your requirements. Essential variables include:

***APP_KEY***: Your unique application key for Laravel. <br>
***MYSQL_RANDOM_ROOT_PASSWORD***: Set to yes for enhanced security. <br>
***MYSQL_USER***, ***MYSQL_PASSWORD***: Database credentials. <br>
***STATIC_CRON_TOKEN***: Security token for scheduled tasks.

***Link to Docker Hub***: https://hub.docker.com/r/nicxx2/fireflyiii-quickstart

### Docker Compose:
```yaml
version: '3.3'

services:
  app:
    image: nicxx2/fireflyiii-quickstart:latest  # Use the Docker Hub image
    container_name: firefly_iii_core
    restart: always
    volumes:
      - /Data/firefly_iii/upload:/var/www/html/storage/upload  # Persistent volume for uploads
      - /Data/firefly_iii/export:/var/www/html/storage/export  # Persistent volume for exports

    networks:
      - firefly_network
    ports:
      - "8081:8080"  # Maps port 8080 inside the container to port 8081 on the host
    depends_on:
      - db
    environment:
      - APP_KEY=aaadd7f048dcb455a863144ccd44bc27
      - MYSQL_RANDOM_ROOT_PASSWORD=yes
      - MYSQL_USER=firefly
      - MYSQL_PASSWORD=secret_firefly_password
      - MYSQL_DATABASE=firefly
      - STATIC_CRON_TOKEN=aaadd7f048dcb455a863144ccd44bc2d

  db:
    image: mariadb:lts
    container_name: firefly_iii_db
    restart: always
    volumes:
      - /Data/firefly_iii/db:/var/lib/mysql  # Persistent volume for database
    networks:
      - firefly_network
    environment:
      - MYSQL_RANDOM_ROOT_PASSWORD=yes
      - MYSQL_USER=firefly
      - MYSQL_PASSWORD=secret_firefly_password
      - MYSQL_DATABASE=firefly

  cron:
    image: alpine
    restart: always
    container_name: firefly_iii_cron
    command: >-
      /bin/sh -c "echo '0 3 * * * wget -qO- http://app:8081/api/v1/cron/$STATIC_CRON_TOKEN' | crontab - && crond -f -L /dev/stdout"
    networks:
      - firefly_network
    depends_on:
      - app
    environment:
      - STATIC_CRON_TOKEN=aaadd7f048dcb455a863144ccd44bc2d

networks:
  firefly_network:
    driver: bridge

```

