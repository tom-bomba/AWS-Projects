<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
class RedisSessionHandler implements SessionHandlerInterface
{
    private $readRedis;
    private $writeRedis;

    public function __construct($readEndpoint, $writeEndpoint)
    {
    $this->readRedis = new Redis();
    if (!$this->readRedis->connect($readEndpoint, 6379)) {
        error_log('Failed to connect to Redis read endpoint');
        throw new Exception('Failed to connect to Redis read endpoint');
        }

    $this->writeRedis = new Redis();
    if (!$this->writeRedis->connect($writeEndpoint, 6379)) {
        error_log('Failed to connect to Redis write endpoint');
        throw new Exception('Failed to connect to Redis write endpoint');
        }
    }


    public function open($savePath, $sessionName)
    {
        return true;
    }

    public function close()
    {
        $this->readRedis->close();
        $this->writeRedis->close();
        return true;
    }

    public function read($id)
    {
    $data = $this->readRedis->get($id);
    if ($data === false) {
        error_log('Failed to read session data from Redis');
        return '';
        }
    return $data;
    }

    public function write($id, $data)
    {
    if ($this->writeRedis->set($id, $data) === false) {
        error_log('Failed to write session data to Redis');
        return false;
        }
    return true;
    }

    public function destroy($id)
    {
    $result = $this->writeRedis->del($id);
    return ($result !== false);
    }

    public function gc($maxlifetime)
    {
        // Implement garbage collection if necessary
        return true;
    }
    public function dumpAllSessions()
    {
        $iterator = NULL;
        $all_sessions = array();
        while($keys = $this->readRedis->scan($iterator)) {
            foreach($keys as $key) {
                $value = $this->readRedis->get($key);
                $all_sessions[$key] = $value;
            }
        }
        return $all_sessions;
    }

}

require 'config.php';
// Usage:
$readEndpoint = REDIS_READER;
$writeEndpoint = REDIS_WRITER;
if (basename($_SERVER['SCRIPT_FILENAME']) !== 'healthcheck.php') {
    if (session_status() == PHP_SESSION_NONE) {
        $handler = new RedisSessionHandler($readEndpoint, $writeEndpoint);
        session_set_save_handler($handler, true);
        session_start();
    }
}


?>
