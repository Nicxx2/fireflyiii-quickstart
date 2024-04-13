#!/bin/bash
set -x  # Enable command echo to see what's being executed

# Define default values for environment variables
MYSQL_DATABASE="${MYSQL_DATABASE:-firefly}"
MYSQL_USER="${MYSQL_USER:-firefly}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-secret_firefly_password}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-yes}"
STATIC_CRON_TOKEN="${STATIC_CRON_TOKEN:-aaadd7f048dcb455a863144ccd44bc2d}"
APP_KEY="${APP_KEY:-aaadd7f048dcb455a863144ccd44bc27}"

echo "Starting entrypoint script..."

echo "Current environment variables:"
env


update_or_append() {
    local file=$1
    local key=$2
    local value=$3
    local temp_file=$(mktemp)

    echo "Attempting to update $key to $value in $file"

    # Use AWK to update or append the environment variable
    if ! awk -F "=" -v key="$key" -v value="$value" '
        BEGIN { found=0 }
        $1 == key { print key "=" value; found=1; next }
        { print $0 }
        END { if (!found) print key "=" value }
    ' "$file" > "$temp_file"; then
        echo "Failed to update $key in $file"
        rm -f "$temp_file"
        return 1
    fi

    # Move the updated temp file to replace the old .env file
    mv "$temp_file" "$file"
    chown www-data:www-data "$file"
    chmod 644 "$file"
    echo "Updated $key in $file successfully"
}

# Attempt to download the latest .env and .db.env files
echo "Downloading .env and .db.env files..."
if ! wget -O /var/www/html/.env https://raw.githubusercontent.com/firefly-iii/firefly-iii/main/.env.example; then
    echo "Failed to download .env file"
    exit 1
fi

if ! wget -O /var/www/html/.db.env https://raw.githubusercontent.com/firefly-iii/docker/main/database.env; then
    echo "Failed to download .db.env file"
    exit 1
fi

# Ensure the file permissions are appropriate before updating
echo "Setting file permissions..."
chown www-data:www-data /var/www/html/.env /var/www/html/.db.env
chmod 644 /var/www/html/.env /var/www/html/.db.env

# Update the .env and .db.env files with environment variables from Docker Compose
echo "Updating .env and .db.env files with environment variables..."
update_or_append /var/www/html/.env "DB_CONNECTION" "mysql"
update_or_append /var/www/html/.env "DB_HOST" "db"
update_or_append /var/www/html/.env "DB_PORT" "3306"
update_or_append /var/www/html/.env "DB_DATABASE" "$MYSQL_DATABASE"
update_or_append /var/www/html/.env "DB_USERNAME" "$MYSQL_USER"
update_or_append /var/www/html/.env "DB_PASSWORD" "$MYSQL_PASSWORD"
update_or_append /var/www/html/.env "STATIC_CRON_TOKEN" "$STATIC_CRON_TOKEN"
update_or_append /var/www/html/.env "APP_KEY" "$APP_KEY"

update_or_append /var/www/html/.db.env "MYSQL_RANDOM_ROOT_PASSWORD" "$MYSQL_ROOT_PASSWORD"
update_or_append /var/www/html/.db.env "MYSQL_USER" "$MYSQL_USER"
update_or_append /var/www/html/.db.env "MYSQL_PASSWORD" "$MYSQL_PASSWORD"
update_or_append /var/www/html/.db.env "MYSQL_DATABASE" "$MYSQL_DATABASE"
update_or_append /var/www/html/.db.env "STATIC_CRON_TOKEN" "$STATIC_CRON_TOKEN"
update_or_append /var/www/html/.db.env "APP_KEY" "$APP_KEY"

# Laravel specific optimizations
echo "Clearing Laravel caches..."
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear
php artisan optimize

# Ensure the database is ready before proceeding
echo "Waiting for DB to be ready..."
while ! mysqladmin ping -h"db" --silent; do
    sleep 1
done

echo "Running database migrations..."
if ! php artisan migrate --force; then
    echo "Migrations failed to run"
    exit 1
else
    echo "Migrations completed successfully"
fi

# Run Apache in the foreground
echo "Starting Apache..."
exec apache2-foreground