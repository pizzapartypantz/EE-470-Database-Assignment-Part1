
<?php
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    // Database connection
    $conn = new mysqli(
        "localhost",
        "u937324307_db_JasonDownin",
        "Downer1967!",
        "u937324307_JasonDowning"
    );

    $conn->set_charset("utf8mb4");

    // SECTION 4: BASE64 DECODING
    // Accept either a Base64 string directly after "?"
    // or the existing regular GET parameters.

    if (isset($_GET["nodeId"])) {
        // Existing, non-Base64 request format
        $params = $_GET;
    } else {
        // Read the raw query string from the URL
        $encodedData = $_SERVER["QUERY_STRING"] ?? "";

        // Support URLs using ?data=BASE64_STRING as well
        if (str_starts_with($encodedData, "data=")) {
            parse_str($encodedData, $queryParams);
            $encodedData = $queryParams["data"] ?? "";
        }

        // Restore URL-encoded characters and remove whitespace
        $encodedData = rawurldecode($encodedData);
        $encodedData = preg_replace('/\s+/', '', $encodedData);

        // Decode the Base64 message
        $decodedData = base64_decode($encodedData, true);

        if ($decodedData === false || $decodedData === "") {
            throw new InvalidArgumentException(
                "Invalid or missing Base64 message."
            );
        }

        // Convert decoded key-value pairs into PHP variables
        parse_str($decodedData, $params);
    }

    // Read the decoded sensor values
    $node = trim($params["nodeId"] ?? "");
    $temp = $params["nodeTemp"] ?? "";
    $humidity = $params["nodeHumidity"] ?? "";
    $time = $params["timeReceived"] ?? "";

    // Validate required fields
    if ($node === "" || $temp === "" || $humidity === "") {
        throw new InvalidArgumentException(
            "Required: nodeId, nodeTemp, nodeHumidity."
        );
    }

    if (!is_numeric($temp) || !is_numeric($humidity)) {
        throw new InvalidArgumentException(
            "Temperature and humidity must be numeric."
        );
    }

    $temp = (float)$temp;
    $humidity = (float)$humidity;

    if ($temp < -10 || $temp > 100 ||
        $humidity < 0 || $humidity > 100) {
        throw new InvalidArgumentException(
            "Reading outside the allowed range."
        );
    }

    // Verify that the sensor is registered
    $check = $conn->prepare(
        "SELECT node_name FROM sensor_register
         WHERE node_name = ?"
    );
    $check->bind_param("s", $node);
    $check->execute();
    $check->store_result();

    $registered = $check->num_rows > 0;
    $check->close();

    if (!$registered) {
        throw new InvalidArgumentException(
            "Rejected: sensor is not registered."
        );
    }

    // Insert the reading
    if ($time === "") {
        $stmt = $conn->prepare(
            "INSERT INTO sensor_data
             (node_name, time_received, temperature, humidity)
             VALUES (?, CURRENT_TIMESTAMP, ?, ?)"
        );
        $stmt->bind_param("sdd", $node, $temp, $humidity);
    } else {
        // Validate timestamp format
        $date = DateTime::createFromFormat(
            '!Y-m-d H:i:s', $time
        );
        $errors = DateTime::getLastErrors();

        if (
            !$date ||
            $date->format('Y-m-d H:i:s') !== $time ||
            ($errors !== false &&
             ($errors['warning_count'] > 0 ||
              $errors['error_count'] > 0))
        ) {
            throw new InvalidArgumentException(
                "Invalid timestamp. Use YYYY-MM-DD HH:MM:SS."
            );
        }

        $stmt = $conn->prepare(
            "INSERT INTO sensor_data
             (node_name, time_received, temperature, humidity)
             VALUES (?, ?, ?, ?)"
        );
        $stmt->bind_param(
            "ssdd", $node, $time, $temp, $humidity
        );
    }

    $stmt->execute();

    echo "New sensor reading inserted successfully.";

    $stmt->close();
    $conn->close();

} catch (InvalidArgumentException $e) {
    http_response_code(400);
    echo htmlspecialchars(
        $e->getMessage(), ENT_QUOTES, 'UTF-8'
    );

} catch (mysqli_sql_exception $e) {
    http_response_code(400);
    echo "Insert rejected: duplicate timestamp or database constraint.";

} catch (Throwable $e) {
    http_response_code(500);
    echo "Database operation failed.";
}
?>

