<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Unset all of the session variables
$_SESSION = array();

if(session_destroy()) {
    // Redirect to login page
    header("location: login.php");
    exit;
} else {
    echo "Failed to destroy session.";
}

exit;
?>
