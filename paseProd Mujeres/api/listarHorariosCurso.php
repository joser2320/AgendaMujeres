<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión y el cursoID estén presentes
if (!isset($data->tokenSesion) || !isset($data->cursoID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$tokenSesion = $data->tokenSesion;
$cursoID = $data->cursoID;

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

// Preparar la llamada al procedimiento almacenado
$spSql = "CALL ObtenerHorariosCurso(?)";
$stmtHorarios = $conn->prepare($spSql);
$stmtHorarios->bind_param("i", $cursoID);

// Ejecutar el procedimiento almacenado
$stmtHorarios->execute();
$result = $stmtHorarios->get_result();

$horarios = [];

// Recoger los resultados y almacenarlos en un array
while ($row = $result->fetch_assoc()) {
    $horarios[] = $row;
}

// Cerrar la conexión a la base de datos
$stmtHorarios->close();
$conn->close();

// Devolver la respuesta en formato JSON
http_response_code(200); // OK
echo json_encode($horarios);
?>
