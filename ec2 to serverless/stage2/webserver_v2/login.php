<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
// Include the DB connection file
require_once 'DBConnect.php';

// Check if form is submitted
if($_SERVER["REQUEST_METHOD"] == "POST"){
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Prepare a select statement
    $sql = "SELECT username, password FROM <UsersTableName> WHERE username = :username";

    if($stmt = $pdo->prepare($sql)){
        // Bind variables to the prepared statement as parameters
        $stmt->bindParam(":username", $param_username, PDO::PARAM_STR);
        
        // Set parameters
        $param_username = trim($_POST["username"]);
        
        // Attempt to execute the prepared statement
        if($stmt->execute()){
            // Check if username exists
            if($stmt->rowCount() == 1){
                if($row = $stmt->fetch()){
                    $hashed_password = $row["password"];
                    if(password_verify($password, $hashed_password)){
                        // Password is correct, start a new session
                        session_start();
                        
                        // Store data in session variables
                        $_SESSION["loggedin"] = true;
                        $_SESSION["username"] = $username;                        
                        
                        // Redirect user to welcome page
                        header("location: index.php");
                    } else{
                        // Display an error message if password is not valid
                        echo "The password you entered was not valid.";
                    }
                }
            } else{
                // Display an error message if username doesn't exist
                echo "No account found with that username.";
            }
        } else{
            echo "Oops! Something went wrong. Please try again later.";
        }
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
    <h2>Login</h2>
    <form action="login.php" method="post">
        <div class="form-group">
            <label>Username</label>
            <input type="text" name="username" class="form-control" required>
        </div>    
        <div class="form-group">
            <label>Password</label>
            <input type="password" name="password" class="form-control" required>
        </div>
        <div class="form-group">
            <input type="submit" class="btn btn-primary" value="Login">
        </div>
    </form>
</body>
</html>
