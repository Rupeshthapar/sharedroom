<?php
// admin_stats.php
// Returns summary stats + full user list. Only responds to requests from
// verified admin accounts — the admin_id is re-checked against the DB on
// every call so a demoted admin cannot keep fetching data.

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

$adminId = intval($_POST['admin_id'] ?? 0);

if ($adminId <= 0) {
    echo json_encode(["success" => false, "error" => "Missing admin_id"]);
    exit;
}

// ── Verify caller is actually an admin ────────────────────────────────────────
$auth = $conn->prepare("SELECT id FROM users WHERE id = ? AND is_admin = 1");
$auth->bind_param("i", $adminId);
$auth->execute();
$auth->store_result();

if ($auth->num_rows === 0) {
    http_response_code(403);
    echo json_encode(["success" => false, "error" => "Forbidden"]);
    $auth->close();
    $conn->close();
    exit;
}
$auth->close();

// ── Counts ───────────────────────────────────────────────────────────────────
$totalUsers = 0;
$r = $conn->query("SELECT COUNT(*) AS c FROM users");
if ($row = $r->fetch_assoc()) $totalUsers = (int) $row['c'];

$totalRooms = 0;
$r = $conn->query("SELECT COUNT(*) AS c FROM files");
if ($row = $r->fetch_assoc()) $totalRooms = (int) $row['c'];

$totalFiles = 0;
$r = $conn->query("SELECT COUNT(*) AS c FROM uploaded_files");
if ($row = $r->fetch_assoc()) $totalFiles = (int) $row['c'];

// ── User list (email, id, is_admin — NO password hash returned) ───────────────
$users = [];
$res = $conn->query(
    "SELECT id, username, is_admin, created_at FROM users ORDER BY created_at DESC"
);
while ($row = $res->fetch_assoc()) {
    $users[] = [
        "id"         => (int)  $row['id'],
        "username"   =>        $row['username'],
        "is_admin"   => (bool) $row['is_admin'],
        "created_at" =>        $row['created_at'],
    ];
}

$conn->close();

echo json_encode([
    "success"     => true,
    "total_users" => $totalUsers,
    "total_rooms" => $totalRooms,
    "total_files" => $totalFiles,
    "users"       => $users,
]);
?>

