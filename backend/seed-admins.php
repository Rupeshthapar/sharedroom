<?php
// seed_admins.php
// ─────────────────────────────────────────────────────────────────────────────
// ONE-TIME SETUP SCRIPT — run once in your browser or via CLI, then DELETE
// this file from the server immediately. It contains plaintext credentials
// and must never be left publicly accessible.
//
// Usage:  http://localhost:8080/backend_classroom/seed_admins.php
//   OR:   php seed_admins.php
// ─────────────────────────────────────────────────────────────────────────────

header("Content-Type: text/plain; charset=UTF-8");

include 'connection.php';

$admins = [
    [
        'email'    => 'rupesh670@gmail.com',
        'password' => '9866194302',
    ],
    [
        'email'    => 'krishna11@gmail.com',
        'password' => '123456789',
    ],
];

$results = [];

foreach ($admins as $admin) {
    $email  = $admin['email'];
    $hash   = password_hash($admin['password'], PASSWORD_BCRYPT);
    // is_admin = 1 flags these accounts as administrators

    // Use INSERT ... ON DUPLICATE KEY UPDATE so re-running the script
    // refreshes the hash and ensures is_admin=1 without throwing a duplicate
    // key error if the account already exists.
    $stmt = $conn->prepare(
        "INSERT INTO users (username, password, is_admin)
         VALUES (?, ?, 1)
         ON DUPLICATE KEY UPDATE password = VALUES(password), is_admin = 1"
    );
    $stmt->bind_param("ss", $email, $hash);

    if ($stmt->execute()) {
        $action    = $stmt->affected_rows === 1 ? 'CREATED' : 'UPDATED';
        $results[] = "[OK]     $email — $action (is_admin=1)";
    } else {
        $results[] = "[FAILED] $email — " . $conn->error;
    }

    $stmt->close();
}

$conn->close();

echo implode("\n", $results) . "\n\n";
echo "─────────────────────────────────────────────────────────\n";
echo "IMPORTANT: Delete this file from the server right now.\n";
echo "           It must not remain publicly accessible.\n";
?>
