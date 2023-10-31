<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
// Include the DB connection file
require_once 'DBConnect.php';

// Check if form is submitted
if($_SERVER["REQUEST_METHOD"] == "POST"){
    $fortune = $_POST['fortune'];

    // Fetch the user's id
    $sql = "SELECT id FROM <UsersTableName> WHERE username = :username";
    if($stmt = $pdo->prepare($sql)){
        $stmt->bindParam(":username", $_SESSION["username"], PDO::PARAM_STR);
        if($stmt->execute()){
            if($stmt->rowCount() == 1){
                if($row = $stmt->fetch()){
                    $userId = $row["id"];
                }
            }
        }
        unset($stmt);
    }

    // Prepare an insert statement
    $sql = "INSERT INTO <AppTableName> (user_id, fortune) VALUES (:user_id, :fortune)";

    if($stmt = $pdo->prepare($sql)){
        // Bind variables to the prepared statement as parameters
        $stmt->bindParam(":user_id", $userId, PDO::PARAM_INT);
        $stmt->bindParam(":fortune", $fortune, PDO::PARAM_STR);

        // Attempt to execute the prepared statement
        if($stmt->execute()){
            // Redirect to welcome page
            header("location: index.php");
        } else{
            echo "Something went wrong. Please try again later.";
        }

        // Close statement
        unset($stmt);
    }
}
// Close connection
unset($pdo);
?>
<!DOCTYPE html>
<html lang="en">
<body>
    <h2>Submit Your Fortune</h2>
    <form action="submit_fortune.php" method="post">
        <div class="form-group">
            <label>Your Fortune</label>
            <textarea name="fortune" class="form-control" required></textarea>
        </div>    
        <div class="form-group">
            <input type="submit" class="btn btn-primary" value="Submit">
        </div>
        <p>
        <a href="submit_fortune.php">Submit a Fortune</a>
        <a href="random_fortune.php">Get Random Fortune</a>
        <a href="index.php">Go Home</a>
        <a href="logout.php">Sign Out</a>
    </p>
    </form>
</body>
</html>
