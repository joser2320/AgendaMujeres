<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión esté presente
if (!isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$tokenSesion = $data->tokenSesion;

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

// Obtener el ID del usuario asociado al token (opcional, si necesitas usarlo)
$sessionData = $sessionResult->fetch_assoc();
$idUsuario = $sessionData['UsuarioID']; // Asumiendo que la columna UsuarioID está en la tabla SESIONES

// Preparar la consulta para obtener todos los datos de la tabla bitacoria_clientes
$sql = "SELECT * FROM bitacoria_clientes";

// Preparar la declaración
$stmt = $conn->prepare($sql);

// Verificar que la preparación fue exitosa
if ($stmt === false) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al preparar la consulta"]);
    exit;
}

// Ejecutar la consulta
$stmt->execute();

// Obtener el resultado
$result = $stmt->get_result();

// Verificar si hay registros
if ($result->num_rows == 0) {
    http_response_code(404); // Not Found
    echo json_encode(["mensaje" => "No se encontraron clientes"]);
    exit;
}

// Inicializar un array para los clientes
$clientes = [];

// Recorrer los resultados y agregar cada cliente al array
while ($clientData = $result->fetch_assoc()) {
    $clientes[] =$clientData;
}

// Retornar la respuesta con todos los clientes
http_response_code(200); // OK
echo json_encode($clientes);

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
