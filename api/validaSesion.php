<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión esté presente
if (!isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["codigo" => -1, "mensaje" => "Falta el token de sesión"]);
    exit;
}

// Asignar el token de sesión a una variable
$tokenSesion = $data->tokenSesion;

// Verificar si la sesión es válida en la base de datos
$sql = "SELECT * FROM sesiones WHERE TokenSesion = ? AND FechaFin > NOW()";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $tokenSesion);
$stmt->execute();
$result = $stmt->get_result();

// Si no se encuentra una sesión activa
if ($result->num_rows == 0) {
    http_response_code(401); // Unauthorized
    echo json_encode(["codigo" => -1, "mensaje" => "Sesión no válida o expirada"]);
    exit;
}

// Si la sesión es válida
echo json_encode(["codigo" => 0,"mensaje" => "Sesión válida"]);

$stmt->close();
$conn->close();
?>
