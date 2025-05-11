<?php
// Configurar la zona horaria de Costa Rica
date_default_timezone_set('America/Costa_Rica');

// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->nombreEstudiante) || !isset($data->cedula) || !isset($data->telefono) || 
    !isset($data->correo) || !isset($data->estadoPago) || 
    !isset($data->idCurso) || !isset($data->idHorario) || !isset($data->tokenSesion)) {
    http_response_code(400);
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$nombreEstudiante = $data->nombreEstudiante;
$cedula = $data->cedula;
$telefono = $data->telefono;
$correo = $data->correo;
$estadoPago = $data->estadoPago;
$idCurso = (int)$data->idCurso;
$idHorario = (int)$data->idHorario;
$tokenSesion = $data->tokenSesion;

// Validar campos obligatorios
if (empty($nombreEstudiante) || empty($cedula) || empty($telefono) || 
    empty($correo) || empty($estadoPago) || empty($tokenSesion)) {
    http_response_code(400);
    echo json_encode(["mensaje" => "Todos los campos son obligatorios"]);
    exit;
}

if ($idCurso <= 0 || $idHorario <= 0) {
    http_response_code(400);
    echo json_encode(["mensaje" => "ID de curso y horario deben ser positivos"]);
    exit;
}

// Verificar si la sesión del usuario está activa
$sessionSql = "SELECT * FROM sesiones WHERE TokenSesion = ? AND FechaFin > NOW()";
$stmt = $conn->prepare($sessionSql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar la consulta de sesión: " . $conn->error]);
    exit;
}
$stmt->bind_param("s", $tokenSesion);
$stmt->execute();
$sessionResult = $stmt->get_result();

if ($sessionResult->num_rows == 0) {
    http_response_code(401);
    echo json_encode(["mensaje" => "Sesión no válida o expirada", "codigo"  => -1]);
    exit;
}
$stmt->close();

// Verificar si ya existe una matrícula con la misma cédula y curso
$checkSql = "SELECT * FROM matriculas WHERE Cedula = ? AND IdCurso = ?";
$stmt = $conn->prepare($checkSql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar la verificación de matrícula: " . $conn->error]);
    exit;
}
$stmt->bind_param("si", $cedula, $idCurso);
$stmt->execute();
$checkResult = $stmt->get_result();

if ($checkResult->num_rows > 0) {
    http_response_code(409);
    echo json_encode(["mensaje" => "Ya existe una matrícula con la misma cédula en este curso"]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

// Ejecutar el procedimiento almacenado
$stmt = $conn->prepare("CALL SP_INSERTAR_MATRICULAS_ADMIN(?, ?, ?, ?, ?, ?, ?)");
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar el procedimiento: " . $conn->error]);
    exit;
}
$stmt->bind_param("ssssssi", $nombreEstudiante, $cedula, $telefono, $correo, $estadoPago, $idCurso, $idHorario);

if ($stmt->execute()) {
    http_response_code(201);
    echo json_encode(["mensaje" => "Matrícula creada exitosamente"]);
} else {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al ejecutar el procedimiento"]);
}

$stmt->close();
$conn->close();
?>
