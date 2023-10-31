<?php
// Include the config file
require_once 'config.php';

// Create new PDO instances
function getDBConnection($type = 'write') {
    try {
        if($type == 'write') {
            $pdo = new PDO("mysql:host=".DB_WRITER_ENDPOINT.";dbname=".DB_NAME, DB_USERNAME, DB_PASSWORD);
        } else if ($type == 'read') {
            $pdo = new PDO("mysql:host=".DB_READER_ENDPOINT.";dbname=".DB_NAME, DB_USER, DB_PASS);
        }
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $pdo;
    } catch (PDOException $e) {
        die("ERROR: Could not connect. " . $e->getMessage());
    }
}
?>
[root@ip-10-0-3-42 html]# cat config.php
<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
// Database configuration
define('DB_WRITER_ENDPOINT', 'app-db-cluster-1.cluster-ce1vrbtvzjjo.us-east-1.rds.amazonaws.com');
define('DB_READER_ENDPOINT', 'app-db-cluster-1.cluster-ro-ce1vrbtvzjjo.us-east-1.rds.amazonaws.com');
define('DB_USER', 'root');
define('DB_PASS', 'iRs00!337Laa');
define('DB_USERNAME', 'root');
define('DB_PASSWORD', 'iRs00!337Laa');
define('DB_NAME', 'fortunes');

// Start session management with a persistent cookie
$lifetime=30*60;
session_set_cookie_params($lifetime);

// Start the session
session_start();
?>