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

// Obtener los datos de la vista `vistadedeudaprofesores`
$vistaSql = "SELECT * FROM listapagosprofesor where EstadoPago = 0;";
$stmtVista = $conn->prepare($vistaSql);
$stmtVista->execute();
$result = $stmtVista->get_result();

$deudas = [];

// Recoger los resultados y almacenarlos en un array
while ($row = $result->fetch_assoc()) {
    $deudas[] = $row;
}

// Cerrar la conexión a la base de datos
$stmtVista->close();
$conn->close();

// Devolver la respuesta en formato JSON
http_response_code(200); // OK
echo json_encode($deudas);
?>
