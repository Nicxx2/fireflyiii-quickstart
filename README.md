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




If you need to include the data_importer alongside Firefly III in your setup, the Docker Compose file provided below will help you configure and run both services. This setup ensures that all components are properly networked and configured to communicate with each other within Docker.


### Docker Compose (including data_importer):

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

  data-importer:
    image: fireflyiii/data-importer:latest
    container_name: firefly_iii_data_importer
    ports:
      - "8082:8080"
    environment:
      FIREFLY_III_ACCESS_TOKEN: "your_ACCESS_TOKEN"
      FIREFLY_III_URL: "http://app:8080"
      NORDIGEN_ID: "your_nordigen_id_here"
      NORDIGEN_KEY: "your_nordigen_key_here"
      SPECTRE_APP_ID: "your_spectre_app_id_here"
      SPECTRE_SECRET: "your_spectre_secret_here"

    networks:
      - firefly_network
    
    depends_on:
      - app
    
    restart: always

networks:
  firefly_network:
    driver: bridge

```



## Setting Up the Firefly III Data Importer

To use the Firefly III Data Importer, you must first have a running instance of Firefly III. The data importer needs to connect to Firefly III using a Personal Access Token, which provides secure access to your Firefly III data. Follow these steps to set up and configure the data importer correctly.

### Prerequisites

- **Running Firefly III Instance**: Ensure that your Firefly III instance is up and running and accessible at the URL you intend to use in the Docker Compose configuration.

### Generating the `FIREFLY_III_ACCESS_TOKEN`

1. **Log in to your Firefly III instance**.
2. Navigate to **Options** > **OAuth** > **Personal Access Tokens**.
3. **Create a New Token**: Provide a descriptive name for the token to remember its use, like "Data Importer Access."
4. **Copy and Store the Token**: The token will be displayed only once. Copy it and store it securely.

### Configuring the Docker Compose

Once you have your Personal Access Token, update the Docker Compose configuration to include this token for the `data-importer` service.

```yaml
data-importer:
  environment:
    FIREFLY_III_ACCESS_TOKEN: "paste_your_token_here"
```
