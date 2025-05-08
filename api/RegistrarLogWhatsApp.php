<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Configurar la zona horaria de Costa Rica
date_default_timezone_set('America/Costa_Rica');

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos requeridos estén presentes
if (!isset($data->Envia) || !isset($data->Recibe) || !isset($data->Mensaje)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar valores a variables
$envia = $data->Envia;
$recibe = $data->Recibe;
$mensaje = $data->Mensaje;
$fechaHora = date("Y-m-d H:i:s"); // Obtener la fecha y hora actual en Costa Rica

// Validar que los campos no estén vacíos
if (empty($envia) || empty($recibe) || empty($mensaje)) {
    http_response_code(400);
    echo json_encode(["mensaje" => "Todos los campos son obligatorios"]);
    exit;
}

// Insertar datos en la tabla
$insertSql = "INSERT INTO WhatsApp_Log (Envia, Recibe, Mensaje, FechaHora) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($insertSql);

if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar la consulta: " . $conn->error]);
    exit;
}

$stmt->bind_param("ssss", $envia, $recibe, $mensaje, $fechaHora);

if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Mensaje insertado correctamente"]);
} else {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al insertar el mensaje"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
