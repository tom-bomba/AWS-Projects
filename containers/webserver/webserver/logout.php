<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Unset all of the session variables
$_SESSION = array();

// Destroy the session.
session_destroy();
session_start();
// Redirect to login page
header("location: login.php");
exit;
?>
