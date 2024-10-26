# Use the latest PHP-FPM image
FROM php:8.3-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libonig-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    sqlite3 \
    libsqlite3-dev

# Install PHP extensions required for Laravel
RUN docker-php-ext-install pdo pdo_sqlite mbstring zip exif pcntl

# Install Composer
RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && \
    apt-get install -y nodejs

# Copy existing application code
COPY . /var/www/html

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --verbose

# Install Node dependencies and build assets
RUN npm install && npm run build

# Copy over the example environment file if .env does not exist
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Generate the Laravel application key
RUN php artisan key:generate

# Optimize the Laravel application
RUN php artisan optimize

# Cache the Laravel configuration
# 
# If you execute the config:cache command during your deployment process, you should be sure that you are only calling the env function from within your configuration files. Once the configuration has been cached, the .env file will not be loaded and all calls to the env function for .env variables will return null.
RUN php artisan config:cache

# Cache Events
RUN php artisan event:cache

# Cache Routes
RUN php artisan route:cache

# Cache Views
RUN php artisan view:cache

# Create an empty SQLite database file
RUN touch database/database.sqlite

# Set appropriate permissions
RUN chmod -R 775 /var/www/html \
    && chown -R www-data:www-data /var/www/html/storage \
    && chown -R www-data:www-data /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/database

# Expose port 9000 and start PHP-FPM server
EXPOSE 9000
CMD ["php-fpm"]
