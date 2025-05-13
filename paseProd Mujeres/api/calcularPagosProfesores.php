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
    echo json_encode(["mensaje" => "Falta el campo obligatorio: tokenSesion"]);
    exit;
}

// Asignar el valor a una variable
$tokenSesion = $data->tokenSesion;

// Verificar si el token de sesión no está vacío
if (empty($tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El campo tokenSesion es obligatorio"]);
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

// Llamar al procedimiento almacenado para insertar el pago
$insertSql = "CALL InsertarPagosProfesores()";
$stmt = $conn->prepare($insertSql);
// $stmt->bind_param("s", $tokenSesion);

// Ejecutar el procedimiento almacenado
if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Se ha realizado el calculo de manera satisfactoria"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al registrar el pago"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
