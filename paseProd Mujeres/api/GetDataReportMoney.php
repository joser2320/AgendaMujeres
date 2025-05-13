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

// Preparar la consulta para obtener todos los datos de la vista vista_movimientos
$sql = "SELECT * FROM vista_movimientos_v2"; // Cambia 'vista_movimientos' por el nombre real de la vista

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
    echo json_encode(["mensaje" => "No se encontraron movimientos"]);
    exit;
}

// Inicializar un array para los movimientos
$movimientos = [];

// Recorrer los resultados y agregar cada movimiento al array
while ($movementData = $result->fetch_assoc()) {
    $movimientos[] = $movementData; // Agregar todo el registro sin mapear
}

// Retornar la respuesta con todos los movimientos
http_response_code(200); // OK
echo json_encode($movimientos);

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
