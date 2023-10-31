# Use the official PHP image from the Docker Hub
FROM php:7.4-apache

# Install necessary packages and PHP extensions
RUN apt-get update && \
    apt-get install -y libzip-dev zip && \
    pecl install redis && \
    docker-php-ext-enable redis && \
    docker-php-ext-install pdo_mysql && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the website files from the local "site/" directory to the "/var/www/html/" directory in the container
COPY ./webserver/* /var/www/html/

# Copy the startup script into the container
COPY ./setup.sh /setup.sh
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log
# Make the startup script executable
RUN chmod +x /setup.sh

EXPOSE 80

# Execute the startup script at container startup
CMD ["/setup.sh"]
