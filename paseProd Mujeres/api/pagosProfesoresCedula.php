<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión y la cédula estén presentes
if (!isset($data->tokenSesion) || !isset($data->cedula)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$tokenSesion = $data->tokenSesion;
$cedula = $data->cedula;

// Validar que la sesión esté activa
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

// Llamar al procedimiento almacenado para actualizar el estado de pago
$spSql = "CALL ActualizarEstadoPagoPorCedula(?)"; // Asumiendo que el SP se llama así
$stmt = $conn->prepare($spSql);
$stmt->bind_param("s", $cedula); // Binding de la cédula

if ($stmt->execute()) {
    // Obtener el resultado del procedimiento almacenado
    $result = $stmt->get_result();
    $response = $result->fetch_assoc(); // Obtener el primer registro

    // Validar el código y mensaje del procedimiento
    if ($response) {
        $codigo = $response['codigo'];
        $mensaje = $response['mensaje'];

        // Devolver la respuesta según el código del procedimiento
        http_response_code($codigo); // Código de respuesta del SP
        echo json_encode(["mensaje" => $mensaje]);
    } else {
        // Si no hay respuesta del SP
        http_response_code(500); // Internal Server Error
        echo json_encode(["mensaje" => "Error al obtener la respuesta del procedimiento almacenado"]);
    }
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al ejecutar el procedimiento almacenado"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
