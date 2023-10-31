<?php
require_once 'DBConnect.php';
ini_set('display_errors', 1);
error_reporting(E_ALL);
// Include the DB connection file

$pdo = getDBConnection('read');
// Prepare a select statement to fetch random fortune
$sql = "SELECT " . AppTableName . ".fortune, " . UsersTableName . ".username FROM " . AppTableName . " JOIN " . UsersTableName . " ON " . AppTableName . ".user_id = " . UsersTableName . ".id ORDER BY RAND() LIMIT 1";
$fortune = "";
$username = "";

if($stmt = $pdo->prepare($sql)){
    // Attempt to execute the prepared statement
    if($stmt->execute()){
        // Check if any fortune exists
        if($stmt->rowCount() == 1){
            if($row = $stmt->fetch()){
                $fortune = $row["fortune"];
                $username = $row["username"];
            }
        } else{
            $fortune = "No fortunes found.";
        }
    } else{
        $fortune = "Oops! Something went wrong. Please try again later.";
    }

    // Close statement
    unset($stmt);
}

// Close connection
unset($pdo);
?>
<!DOCTYPE html>
<html lang="en">
<body>
    <h2>Get Your Fortune</h2>
    <form action="random_fortune.php" method="get">
        <input type="submit" class="btn btn-primary" value="Get Fortune">
    </form>
    <div>
        <?php
            // Display the fortune and the username
            echo "Your fortune is: " . $fortune . "<br>";
            echo "Submitted by: " . $username;
        ?>
    </div>
    <p>
        <a href="submit_fortune.php">Submit a Fortune</a>
        <a href="random_fortune.php">Get Random Fortune</a>
        <a href="index.php">Go Home</a>
        <a href="logout.php">Sign Out</a>
    </p>
</body>
</html>
