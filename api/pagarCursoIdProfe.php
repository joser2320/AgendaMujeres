<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->tokenSesion) || !isset($data->cursoID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$tokenSesion = $data->tokenSesion;
$cursoID = $data->cursoID;

// Validar que los campos no estén vacíos
if (empty($tokenSesion) || empty($cursoID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El token de sesión y el cursoID son obligatorios"]);
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

// Llamar al procedimiento almacenado para actualizar los pagos
$spSql = "CALL PagarProfesoresPorCurso(?)";
$stmt = $conn->prepare($spSql);
$stmt->bind_param("i", $cursoID);

if ($stmt->execute()) {
    // Verificar si el procedimiento afectó filas
    $stmt->store_result(); // Guardar los resultados
    if ($stmt->affected_rows > 0) {
        // Respuesta exitosa
        http_response_code(200); // OK
        echo json_encode(["mensaje" => "Pagos actualizados exitosamente", "actualizados" => $stmt->affected_rows]);
    } else {
        http_response_code(404); // Not Found
        echo json_encode(["mensaje" => "No se encontraron pagos pendientes para este curso"]);
    }
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al ejecutar el procedimiento almacenado"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
