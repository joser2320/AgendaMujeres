<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->idMatricula) || !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$idMatricula = $data->idMatricula;
$tokenSesion = $data->tokenSesion;

// Validar que no estén vacíos
if (empty($idMatricula) || empty($tokenSesion)) {
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

if ($sessionResult->num_rows == 0) {
    http_response_code(401); // Unauthorized
    echo json_encode(["mensaje" => "Sesión no válida o expirada", "codigo" => -1]);
    exit;
}

// Ejecutar el procedimiento almacenado
$spSql = "CALL ValidarCuotasPagadasEnvioMensaje(?)";
$stmt = $conn->prepare($spSql);
$stmt->bind_param("i", $idMatricula);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode(["resultado" => $row['Resultado']]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al ejecutar el procedimiento almacenado"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
