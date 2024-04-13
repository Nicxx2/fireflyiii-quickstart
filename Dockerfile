# Use the official Firefly III core image as the base
FROM fireflyiii/core:latest

# Install system dependencies required for Laravel, MySQL client, and general tools
RUN apt-get update && \
    apt-get install -y wget python3 default-mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  # Clean up to reduce image size

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# Create directories needed by Laravel
RUN mkdir -p storage/framework/sessions \
             storage/framework/views \
             storage/framework/cache \
             storage/framework/cache/data \
             bootstrap/cache

# Copy the application code
COPY . /var/www/html

# Install PHP dependencies without running scripts or autoloader, then optimize autoload files
RUN composer install --no-scripts --no-autoloader && \
    composer dump-autoload --optimize

# Correct ownership and permissions to ensure Laravel can run smoothly
RUN chown -R www-data:www-data . && \
    chmod -R 775 storage bootstrap/cache

# Copy the entry script, set executable permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint to the custom script
ENTRYPOINT ["/entrypoint.sh"]

# Start Apache in the foreground
CMD ["apache2-foreground"]