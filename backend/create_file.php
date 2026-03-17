<?php
// create_file.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

$title   = trim($_POST['title']   ?? '');
$content = trim($_POST['content'] ?? '');
$ownerId = intval($_POST['owner_id'] ?? 0);

if ($title === '' || $ownerId <= 0) {
    echo json_encode(["success" => false, "error" => "Title and owner_id are required"]);
    exit;
}

// Generate a random 6-char code; retry up to 5 times on collision
$code  = '';
$tries = 0;
do {
    $code = substr(str_shuffle("ABCDEFGHJKLMNPQRSTUVWXYZ23456789"), 0, 6);
    $chk  = $conn->prepare("SELECT id FROM files WHERE access_code = ?");
    $chk->bind_param("s", $code);
    $chk->execute();
    $chk->store_result();
    $exists = $chk->num_rows > 0;
    $chk->close();
    $tries++;
} while ($exists && $tries < 5);

if ($exists) {
    echo json_encode(["success" => false, "error" => "Could not generate a unique code — please try again"]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("INSERT INTO files (title, content, access_code, owner_id) VALUES (?, ?, ?, ?)");
$stmt->bind_param("sssi", $title, $content, $code, $ownerId);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "code" => $code, "file_id" => $conn->insert_id]);
} else {
    echo json_encode(["success" => false, "error" => $conn->error]);
}

$stmt->close();
$conn->close();
?>
