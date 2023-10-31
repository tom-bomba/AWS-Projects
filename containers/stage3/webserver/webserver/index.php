<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Check if the user is logged in
if(!isset($_SESSION["loggedin"]) || $_SESSION["loggedin"] !== true){
    // If not, redirect to login page
    header("location: login.php");
    exit;
}
$all_sessions = [];
try {
    $all_sessions = $handler->dumpAllSessions();
    var_dump($all_sessions);
} catch (Exception $e) {
    error_log('Error dumping all sessions: ' . $e->getMessage());
}
?>
 
<!DOCTYPE html>
<html lang="en">
<body>
    <div class="page-header">
        <h1>Hi, <b><?php echo htmlspecialchars($_SESSION["username"]); ?></b>. Welcome to our site.</h1>

    </div>
    <p>
        <a href="submit_fortune.php">Submit a Fortune</a>
        <a href="random_fortune.php">Get Random Fortune</a>
        <a href="logout.php">Sign Out</a>
    </p>
</body>
</html>
