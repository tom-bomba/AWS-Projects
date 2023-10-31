<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
require_once 'config.php';
// Create new PDO instances
function getDBConnection($type = 'write') {
    try {
        if($type == 'write') {
            $pdo = new PDO("mysql:host=".DB_WRITER_ENDPOINT.";dbname=".DB_NAME, DB_USER, DB_PASS);
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
