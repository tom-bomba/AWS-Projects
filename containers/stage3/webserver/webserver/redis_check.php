<?php
// Include your configuration file if necessary
require_once 'config.php';

// Create new Redis instances for reading and writing
$readRedis = new Redis();
$writeRedis = new Redis();

// Connect to the Redis servers
$readConnected = $readRedis->connect(REDIS_READER, 6379);
$writeConnected = $writeRedis->connect(REDIS_WRITER, 6379);

// Check the connections
if ($readConnected) {
    echo 'Read Redis connected successfully.<br>';
    // Send a PING command to the read server
    $readPing = $readRedis->ping();
    echo 'Read Redis PING response: ' . $readPing . '<br>';
} else {
    echo 'Failed to connect to Read Redis.<br>';
}

if ($writeConnected) {
    echo 'Write Redis connected successfully.<br>';
    // Send a PING command to the write server
    $writePing = $writeRedis->ping();
    echo 'Write Redis PING response: ' . $writePing . '<br>';
} else {
    echo 'Failed to connect to Write Redis.<br>';
}

// Close the Redis connections
$readRedis->close();
$writeRedis->close();
?>
