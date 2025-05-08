<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->email) || !isset($data->password) || !isset($data->fullName) || !isset($data->tokenSesion) ||
    !isset($data->rolAdmin) || !isset($data->rolServicio) || !isset($data->rolContable) || !isset($data->rolReporteria)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$email = $data->email;
$password = $data->password;
$fullName = $data->fullName;
$tokenSesion = $data->tokenSesion; // Token de sesión
$rolAdmin = $data->rolAdmin;
$rolServicio = $data->rolServicio;
$rolContable = $data->rolContable;
$rolReporteria = $data->rolReporteria;

// Validar que no estén vacíos
if (empty($email) || empty($password) || empty($fullName) || empty($tokenSesion)) {
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

// Obtener el ID del usuario de la sesión activa
$sessionData = $sessionResult->fetch_assoc();
$usuarioID = $sessionData['UsuarioID'];

// Verificar si el correo ya existe
$sql = "SELECT * FROM usuarios WHERE Email = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    http_response_code(409); // Conflict
    echo json_encode(["mensaje" => "El correo electrónico ya está registrado"]);
    exit;
}

// Encriptar la contraseña
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Llamar al procedimiento almacenado para crear el usuario

// Valor de activo (1 si está activo, 0 si está inactivo)
$activo = 1; // Asumiendo que el usuario está activo al crear

// Convertir los valores booleanos a enteros
$rolAdmin = $rolAdmin ? 1 : 0;
$rolServicio = $rolServicio ? 1 : 0;
$rolContable = $rolContable ? 1 : 0;
$rolReporteria = $rolReporteria ? 1 : 0;

$insertSql = "CALL SP_CREAR_USUARIO(?, ?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($insertSql);
$stmt->bind_param("ssssiiii", $email, $hashedPassword, $fullName, $activo, $rolAdmin, $rolServicio, $rolContable, $rolReporteria);



// Ejecutar el procedimiento almacenado
if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Usuario registrado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al registrar el usuario"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
