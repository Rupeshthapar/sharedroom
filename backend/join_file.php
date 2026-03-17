<?php
// join_file.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

$code = strtoupper(trim($_POST['code'] ?? ''));

if (strlen($code) !== 6) {
    echo json_encode(["success" => false, "error" => "Code must be exactly 6 characters"]);
    exit;
}

$stmt = $conn->prepare("SELECT * FROM files WHERE access_code = ?");
$stmt->bind_param("s", $code);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    // FIX: was missing "success" => true — Flutter's data['success']==true check
    // always evaluated to false even for a valid code, so the app showed an error
    // instead of navigating to the room.
    $row['success'] = true;
    echo json_encode($row);
} else {
    echo json_encode(["success" => false, "error" => "Room not found — check the code and try again"]);
}

$stmt->close();
$conn->close();
?>
