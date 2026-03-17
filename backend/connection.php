<?php
// connection.php
// Configured for XAMPP on Linux
// Document root: /opt/lampp/htdocs/
// XAMPP MySQL socket: /opt/lampp/var/mysql/mysql.sock

$host = "localhost";
$user = "root";
$pass = "";       // XAMPP default — update if you set a root password in phpMyAdmin
$db   = "demo_db";
$port = 3306;

// On Linux, XAMPP MySQL uses a Unix socket, not TCP.
// Passing the socket path as host forces PHP to use the right MySQL instance
// instead of accidentally connecting to the system MariaDB.
$socket = "/opt/lampp/var/mysql/mysql.sock";

$conn = new mysqli();
$conn->init();
$conn->real_connect($host, $user, $pass, $db, $port, $socket);

if ($conn->connect_error) {
    echo json_encode([
        "success" => false,
        "error"   => "DB connection failed: " . $conn->connect_error,
    ]);
    exit;
}

$conn->set_charset("utf8mb4");
?>
