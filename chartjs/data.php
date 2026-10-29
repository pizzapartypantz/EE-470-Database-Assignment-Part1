
<?php
header('Content-Type: application/json; charset=utf-8');

mysqli_report(MYSQLI_REPORT_OFF);

$mysqli = new mysqli(
    "localhost",
    "u937324307_db_JasonDownin",
    "Downer1967!",
    "u937324307_JasonDowning"
);

if ($mysqli->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed"]);
    exit;
}

$mysqli->set_charset("utf8mb4");

// Read the selected node; default to node_1
$nodeName = $_GET['node'] ?? 'node_1';

// Validate the node name
if (!preg_match('/^[A-Za-z0-9_-]+$/', $nodeName)) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid node name"]);
    $mysqli->close();
    exit;
}

// Retrieve the selected node's sensor readings
$sql = "SELECT time_received, temperature, humidity
        FROM sensor_data
        WHERE node_name = ?
        ORDER BY time_received ASC";

$stmt = $mysqli->prepare($sql);

if (!$stmt) {
    http_response_code(500);
    echo json_encode(["error" => "Query preparation failed"]);
    $mysqli->close();
    exit;
}

$stmt->bind_param("s", $nodeName);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode($data);

$stmt->close();
$mysqli->close();
?>
