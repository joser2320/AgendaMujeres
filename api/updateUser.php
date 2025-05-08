<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->usuarioID) || !isset($data->email) || !isset($data->password) || !isset($data->fullName) || 
    !isset($data->tokenSesion) || !isset($data->rolAdmin) || !isset($data->rolServicio) || 
    !isset($data->rolContable) || !isset($data->rolReporteria) || !isset($data->activo)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$usuarioID = $data->usuarioID;
$email = $data->email;
$password = $data->password;
$fullName = $data->fullName;
$tokenSesion = $data->tokenSesion; // Token de sesión
$rolAdmin = $data->rolAdmin ? 1 : 0;
$rolServicio = $data->rolServicio ? 1 : 0;
$rolContable = $data->rolContable ? 1 : 0;
$rolReporteria = $data->rolReporteria ? 1 : 0;
$activo = $data->activo ? 1 : 0; // Convertir a 1 o 0

// Validar que no estén vacíos
if (empty($usuarioID) || empty($email) || empty($password) || empty($fullName) || empty($tokenSesion)) {
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
    echo json_encode(["mensaje" => "Sesión no válida o expirada", "codigo"  => -1]);
    exit;
}

// Encriptar la contraseña
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Verificar si el usuario ya existe en la base de datos
$selectSql = "SELECT * FROM usuarios WHERE ID = ?";
$stmt = $conn->prepare($selectSql);
$stmt->bind_param("i", $usuarioID);
$stmt->execute();
$result = $stmt->get_result();

// Si el usuario no existe, retornar un error
if ($result->num_rows == 0) {
    http_response_code(404); // Not Found
    echo json_encode(["mensaje" => "El usuario no existe"]);
    exit;
}

// Llamar al procedimiento almacenado para actualizar el usuario
$updateSql = "CALL SP_EDITAR_USUARIO_V2(?, ?, ?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($updateSql);
$stmt->bind_param("isssiiiii", $usuarioID, $email, $hashedPassword, $fullName, $rolAdmin, $rolServicio, $rolContable, $rolReporteria, $activo);

// Ejecutar el procedimiento almacenado
if ($stmt->execute()) {
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "Usuario actualizado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al actualizar el usuario"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
