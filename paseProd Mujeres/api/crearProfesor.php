<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->nombreProfesor) || !isset($data->correo) || !isset($data->telefono) || !isset($data->cedula) || !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$nombreProfesor = $data->nombreProfesor;
$correo = $data->correo;
$telefono = $data->telefono;
$cedula = $data->cedula;
$tokenSesion = $data->tokenSesion; // Token de sesión

// Validar que no estén vacíos
if (empty($nombreProfesor) || empty($correo) || empty($telefono) || empty($cedula) || empty($tokenSesion)) {
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

// Verificar si el correo del profesor ya existe
$sql = "SELECT * FROM profesores WHERE Correo = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $correo);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    http_response_code(409); // Conflict
    echo json_encode(["mensaje" => "El correo electrónico del profesor ya está registrado o no es valido"]);
    exit;
}

// Insertar los datos del nuevo profesor en la base de datos
$insertSql = "INSERT INTO profesores (NombreProfesor, Correo, Telefono, Cedula) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($insertSql);
$stmt->bind_param("ssss", $nombreProfesor, $correo, $telefono, $cedula);

if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Profesor registrado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al registrar el profesor revise los datos ingresados"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
