<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->idMatricula) || !isset($data->formaPago) || !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$idMatricula = $data->idMatricula;
$formaPago = $data->formaPago;
$tokenSesion = $data->tokenSesion;

// Validar que no estén vacíos
if (empty($idMatricula) || empty($formaPago) || empty($tokenSesion)) {
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

// Obtener el ID del usuario de la sesión activa (opcional)
$sessionData = $sessionResult->fetch_assoc();
$usuarioID = $sessionData['UsuarioID'];

// Verificar si la matrícula existe
$matriculaSql = "SELECT * FROM matriculas WHERE Id = ?";

$stmt = $conn->prepare($matriculaSql);
$stmt->bind_param("i", $idMatricula);
$stmt->execute();
$matriculaResult = $stmt->get_result();

if ($matriculaResult->num_rows == 0) {
    http_response_code(404); // Not Found
    echo json_encode(["mensaje" => "La matrícula no existe"]);
    exit;
}

// Actualizar el método de pago de la matrícula
$updateSql = "UPDATE matriculas SET formaPago = ? WHERE Id = ?";

$updateSql = "UPDATE matriculas SET formaPago = ? WHERE Id = ?";

$stmt = $conn->prepare($updateSql);

// Verificar si la preparación de la consulta falló
if ($stmt === false) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error en la preparación de la consulta: " . $conn->error]);
    exit;
}

$stmt->bind_param("si", $formaPago, $idMatricula);

if ($stmt->execute()) {
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "Método de pago actualizado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al actualizar el método de pago"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
