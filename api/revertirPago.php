<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->tokenSesion) || !isset($data->idMovimiento) || !isset($data->idMatricula)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$tokenSesion = $data->tokenSesion;
$idMovimiento = $data->idMovimiento;
$idMatricula = $data->idMatricula;

// Validar que los campos no estén vacíos
if (empty($tokenSesion) || empty($idMovimiento) || empty($idMatricula)) {
    http_response_code(400);
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

// Llamar al procedimiento almacenado
try {
    $spSql = "CALL SP_RevertirPago(?, ?)";
    $stmt = $conn->prepare($spSql);
    $stmt->bind_param("ii", $idMovimiento, $idMatricula);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["mensaje" => "Movimiento eliminado y matrícula actualizada correctamente", "codigo" => 0]);
    } else {
        throw new Exception($stmt->error);
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(["mensaje" => "Error al ejecutar el procedimiento: " . $e->getMessage(), "codigo" => -2]);
}

// Cerrar recursos
$stmt->close();
$conn->close();
?>
