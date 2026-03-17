<?php
// upload_file.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

// ── Validate inputs ──────────────────────────────────────────────────────────

$roomCode = strtoupper(trim($_POST['room_code'] ?? ''));

if ($roomCode === '') {
    echo json_encode(["success" => false, "error" => "Missing room_code"]);
    exit;
}

if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    $code = $_FILES['file']['error'] ?? -1;
    echo json_encode(["success" => false, "error" => "File upload error (code $code)"]);
    exit;
}

// ── Verify the room exists ───────────────────────────────────────────────────

$stmt = $conn->prepare("SELECT id FROM files WHERE access_code = ?");
$stmt->bind_param("s", $roomCode);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows === 0) {
    echo json_encode(["success" => false, "error" => "Room not found"]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

// ── Validate file ────────────────────────────────────────────────────────────

$file     = $_FILES['file'];
$origName = basename($file['name']);
$fileSize = $file['size'];
$tmpPath  = $file['tmp_name'];

// 50 MB hard limit
if ($fileSize > 50 * 1024 * 1024) {
    echo json_encode(["success" => false, "error" => "File exceeds 50 MB limit"]);
    exit;
}

// Block dangerous extensions
$ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
$blocked = ['php', 'php3', 'php4', 'php5', 'phtml', 'exe', 'sh', 'bat', 'cmd'];
if (in_array($ext, $blocked, true)) {
    echo json_encode(["success" => false, "error" => "File type not allowed"]);
    exit;
}

// ── Save to disk ─────────────────────────────────────────────────────────────

// Sanitise filename — keep only alphanumerics, dots, dashes, underscores
$safeName  = preg_replace('/[^a-zA-Z0-9._-]/', '_', $origName);
$uploadDir = __DIR__ . '/uploads/' . $roomCode . '/';

if (!is_dir($uploadDir) && !mkdir($uploadDir, 0755, true)) {
    echo json_encode(["success" => false, "error" => "Could not create upload directory"]);
    exit;
}

$destFile = $uploadDir . time() . '_' . $safeName;

if (!move_uploaded_file($tmpPath, $destFile)) {
    echo json_encode(["success" => false, "error" => "Failed to save file"]);
    exit;
}

// ── Persist metadata ─────────────────────────────────────────────────────────

$stmt = $conn->prepare(
    "INSERT INTO uploaded_files (room_code, file_name, file_path, file_size) VALUES (?, ?, ?, ?)"
);
$stmt->bind_param("sssi", $roomCode, $safeName, $destFile, $fileSize);

if ($stmt->execute()) {
    echo json_encode([
        "success"   => true,
        "file_id"   => $conn->insert_id,
        "file_name" => $safeName,
    ]);
} else {
    // File was saved to disk but DB insert failed — still report partial success
    // so the client doesn't silently lose the upload.
    echo json_encode([
        "success"  => false,
        "error"    => "File saved but database record failed: " . $conn->error,
    ]);
}

$stmt->close();
$conn->close();
?>
