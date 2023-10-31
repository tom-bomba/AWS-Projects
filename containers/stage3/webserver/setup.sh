#!/bin/bash -xe

DB_USERNAME=$(echo "$DB_USERNAME" | base64 --decode)
DB_PASSWORD=$(echo "$DB_PASSWORD" | base64 --decode)

for file in /var/www/html/*.php; do
  sed -i "s/<DB_WRITER_ENDPOINT>/$DB_WRITER_ENDPOINT/g" "$file"
  sed -i "s/<DB_READER_ENDPOINT>/$DB_READER_ENDPOINT/g" "$file"
  sed -i "s/<DB_USERNAME>/$DB_USERNAME/g" "$file"
  sed -i "s/<DB_PASSWORD>/$DB_PASSWORD/g" "$file"
  sed -i "s/<UsersTableName>/users/g" "$file"
  sed -i "s/<AppTableName>/fortunes/g" "$file"
  sed -i "s/<DB_NAME>/$DB_NAME/g" "$file"
  sed -i "s/<REDIS_WRITER>/$REDIS_WRITER/g" "$file"
  sed -i "s/<REDIS_READER>/$REDIS_READER/g" "$file"
done
chown -R www-data:www-data /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo 'auto_prepend_file = "/var/www/html/redis_session_setup.php"' >> 	/usr/local/etc/php/php.ini

# Start Apache
apache2-foreground
