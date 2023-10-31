<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
// Database configuration
define('DB_WRITER_ENDPOINT', '<DB_WRITER_ENDPOINT>');
define('DB_READER_ENDPOINT', '<DB_READER_ENDPOINT>');
define('DB_USER', '<DB_USERNAME>');
define('DB_PASS', '<DB_PASSWORD>');
define('DB_NAME', '<DB_NAME>');

// Start session management with a persistent cookie
$lifetime=30*60;
session_set_cookie_params($lifetime);

// Start the session
session_start();
?>
