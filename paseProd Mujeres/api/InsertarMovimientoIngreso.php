<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->idMatricula)  ||
    !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$idMatricula = $data->idMatricula;
$cuotaPagar = $data->cuotaPagar;
$notas = $data->notas;
$comprobante = $data->comprobante;
$tokenSesion = $data->tokenSesion; // Token de sesión

// Validar que no estén vacíos
if (empty($idMatricula)  || empty($tokenSesion)|| empty($cuotaPagar))  {
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

// Llamar al procedimiento almacenado para insertar el movimiento
$insertSql = "CALL InsertarMovimientoPorMatriculaPagoCliente(?, ?, ?, ?)";
$stmt = $conn->prepare($insertSql);
$stmt->bind_param("idss", $idMatricula, $cuotaPagar, $notas, $comprobante);

// Ejecutar el procedimiento almacenado
if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Movimiento registrado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al registrar el movimiento"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
