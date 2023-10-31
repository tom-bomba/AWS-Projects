<?php
require_once 'config.php';
ini_set('session.save_handler', 'redis');
ini_set('session.save_path', 'tcp://' . REDIS_WRITER . ':6379');
?>
