<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
// Include the DB connection file
require_once 'DBConnect.php';

// Check if form is submitted
if($_SERVER["REQUEST_METHOD"] == "POST"){
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Prepare an insert statement
    $sql = "INSERT INTO <UsersTableName> (username, password) VALUES (:username, :password)";

    if($stmt = $pdo->prepare($sql)){
        // Bind variables to the prepared statement as parameters
        $stmt->bindParam(":username", $param_username, PDO::PARAM_STR);
        $stmt->bindParam(":password", $param_password, PDO::PARAM_STR);
        
        // Set parameters
        $param_username = $username;
        $param_password = password_hash($password, PASSWORD_DEFAULT); // Creates a password hash

        // Attempt to execute the prepared statement
        if($stmt->execute()){
            // Redirect to login page
            header("location: login.php");
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
    <h2>Register</h2>
    <form action="register.php" method="post">
        <div class="form-group">
            <label>Username</label>
            <input type="text" name="username" class="form-control" required>
        </div>    
        <div class="form-group">
            <label>Password</label>
            <input type="password" name="password" class="form-control" required>
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
