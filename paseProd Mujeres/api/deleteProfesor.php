<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->tokenSesion) || !isset($data->profesorID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$tokenSesion = $data->tokenSesion;
$profesorID = $data->profesorID;

// Validar que los campos no estén vacíos
if (empty($tokenSesion) || empty($profesorID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Todos los campos son obligatorios"]);
    exit;
}

// Verificar si la sesión del usuario está activa
$sessionSql = "SELECT * FROM sesiones WHERE TokenSesion = ? AND FechaFin > NOW()";
$stmt = $conn->prepare($sessionSql);
$stmt->bind_param("s", $tokenSesion);
$stmt->execute();
$sessionResult = $stmt->get_result();

// Si no se encuentra la sesión activa, retornar error
if ($sessionResult->num_rows == 0) {
    http_response_code(401); // Unauthorized
    echo json_encode(["mensaje" => "Sesión no válida o expirada", "codigo" => -1]);
    exit;
}

// Llamar al procedimiento almacenado para eliminar al profesor
$spSql = "CALL EliminarProfesor(?)";
$stmt = $conn->prepare($spSql);
$stmt->bind_param("i", $profesorID);
$stmt->execute();
$result = $stmt->get_result();

// Obtener el resultado del SP
$response = $result->fetch_assoc();

// Verificar el código retornado por el SP
if ($response['codigo'] == 0) {
    http_response_code(200); // OK
    echo json_encode(["mensaje" => $response['mensaje'], "codigo" => $response['codigo']]);
} else {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => $response['mensaje'], "codigo" => $response['codigo']]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
