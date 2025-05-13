<?php
// Establecer la zona horaria de Costa Rica
date_default_timezone_set('America/Costa_Rica');

// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->IdCurso) || !isset($data->IdProfesor) || !isset($data->notas) || !isset($data->comprobante) || !isset($data->monto) || !isset($data->tokenSesion) || !isset($data->IdPago)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$IdCurso = $data->IdCurso;
$IdProfesor = $data->IdProfesor;
$notas = $data->notas;
$comprobante = $data->comprobante;
$monto = $data->monto;
$IdPago = $data->IdPago;
$tokenSesion = $data->tokenSesion;

// Obtener la fecha y hora actual en Costa Rica
$fecha = date('Y-m-d H:i:s'); // Formato 'YYYY-MM-DD HH:MM:SS'

// Validar que no estén vacíos
if (empty($IdCurso) || empty($IdProfesor) || empty($tokenSesion) || empty($monto)) {
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

// Definir el tipo de movimiento (puedes ajustarlo según tu lógica, por ejemplo, tipo 1 para pago)
$tipoMovimiento = 2;  // Suponiendo que '2' corresponde al tipo de movimiento para pago

// Llamar al procedimiento almacenado para insertar el movimiento
$insertSql = "CALL InsertarMovimientoPagoProfesor(?, ?, ?, ?, ?, ?, ?,?)";
$stmt = $conn->prepare($insertSql);

// Aquí bindamos todos los parámetros, incluyendo el nuevo parámetro 'IdPago'
$stmt->bind_param("idiisssi", $tipoMovimiento, $monto, $IdCurso, $IdProfesor, $notas, $comprobante, $fecha, $IdPago);

// Ejecutar el procedimiento almacenado
if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Movimiento registrado exitosamente"]);
} else {
    // Capturar el error y devolverlo como mensaje
    $error = $stmt->error;
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al registrar el movimiento", "error" => $error]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
