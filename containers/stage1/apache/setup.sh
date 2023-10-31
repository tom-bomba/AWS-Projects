#!/bin/bash -xe
for file in /var/www/html/*.php; do
  sed -i "s/<DB_WRITER_ENDPOINT>/$DB_WRITER_ENDPOINT/g" "$file"
  sed -i "s/<DB_READER_ENDPOINT>/$DB_READER_ENDPOINT/g" "$file"
  sed -i "s/<DB_USERNAME>/$DB_USERNAME/g" "$file"
  sed -i "s/<DB_PASSWORD>/$DB_PASSWORD/g" "$file"
  sed -i "s/<UsersTableName>/users/g" "$file"
  sed -i "s/<AppTableName>/fortunes/g" "$file"
  sed -i "s/<DB_NAME>/$DB_NAME/g" "$file"
done
chown -R www-data:www-data /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# Start Apache
apache2-foreground
