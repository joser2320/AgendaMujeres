<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión esté presente
if (!isset($data->token)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$tokenSesion = $data->token;

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

// Obtener los datos de la vista de resumen contable desde la base de datos
$resumenSql = "SELECT * FROM vista_resumen_conta_v2";
$stmtResumen = $conn->prepare($resumenSql);
$stmtResumen->execute();
$result = $stmtResumen->get_result();

// Recoger los resultados y almacenarlos en un array
$resumen = $result->fetch_assoc(); // Solo hay una fila en la vista

// Cerrar la conexión a la base de datos
$stmtResumen->close();
$conn->close();

// Devolver la respuesta en formato JSON
http_response_code(200); // OK
echo json_encode($resumen);
?>
