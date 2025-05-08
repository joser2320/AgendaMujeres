<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el ID de curso y el token de sesión estén presentes
if (!isset($data->idCurso)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a las variables
$idCurso = $data->idCurso;

// Validar que no estén vacíos
if (empty($idCurso)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Todos los campos son obligatorios"]);
    exit;
}

// Consulta para obtener los totales de pagado y pendiente
$validationSql = "
    SELECT
        SUM(CASE WHEN m.estadoPago = 'Pagado' THEN c.Precio ELSE 0 END) AS total_pagado,
        SUM(CASE WHEN m.estadoPago = 'Pendiente' THEN c.Precio ELSE 0 END) AS total_pendiente
    FROM
        matriculas m
    JOIN
        cursos c ON m.IdCurso = c.ID
    WHERE
        m.IdCurso = ?
";
$stmt = $conn->prepare($validationSql);
$stmt->bind_param("i", $idCurso);
$stmt->execute();
$result = $stmt->get_result();
$totals = $result->fetch_assoc();

// Verificar si total_pagado es menor que total_pendiente
if ($totals['total_pagado'] < $totals['total_pendiente']) {
    http_response_code(403); // Forbidden
    echo json_encode(["mensaje" => "Aún nos puede pagar al profesor. Hay matriculas pendientes de cobro."]);
    exit;
}

// Consulta para verificar si existen registros con el idCurso y tipoMovimiento = 2
$checkSql = "SELECT COUNT(*) as count FROM movimientosdinero WHERE idCurso = ? AND tipoMovimiento = 2";
$stmt = $conn->prepare($checkSql);
$stmt->bind_param("i", $idCurso);
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();

// Comprobar si se encontraron registros
if ($row['count'] > 0) {
    http_response_code(409); // Conflict
    echo json_encode(["mensaje" => "Ya existe un registro de pago para este curso."]);
} else {
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "No se encontraron registros de pago para este curso."]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
