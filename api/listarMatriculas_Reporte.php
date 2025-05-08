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

// Obtener las matrículas y los nombres de los cursos desde la base de datos
$matriculasSql = "

   SELECT 
    m.Id, 
    m.Cedula, 
    m.Telefono,
    m.Nombre AS NombreCompleto,
    m.Correo, 
    m.estadoPago, 
    c.NombreCurso,
    CONCAT(HC.DiaSemana, ' ', '(', HC.HoraInicio, '-', HC.HoraFin,')') AS Horario,
    c.Precio,
    ROUND(c.Precio / c.cantidadCuotas, 2) AS MontoCuota,
    m.CuotasPendientes,

    (
        SELECT GROUP_CONCAT(DATE_FORMAT(DATE_ADD(
            CASE 
                WHEN DAY(LAST_DAY(c.FechaInicio)) - DAY(c.FechaInicio) + 1 
                     < DAY(DATE_ADD(c.FechaInicio, INTERVAL 1 MONTH)) 
                THEN DATE_ADD(c.FechaInicio, INTERVAL 1 MONTH)
                ELSE c.FechaInicio
            END,
            INTERVAL seq MONTH), '%M') ORDER BY seq SEPARATOR ', ')
        FROM (
            SELECT 0 AS seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL 
            SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
            SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
        ) AS seq_table
        WHERE seq >= c.cantidadCuotas - m.CuotasPendientes
          AND seq < c.cantidadCuotas
    ) AS MesesPendientes,

    ROUND((c.Precio / c.cantidadCuotas) * m.CuotasPendientes, 2) AS MontoAdeudado, 
    COALESCE(NULLIF(m.comprobante, ''), '0') AS comprobante,  
    COALESCE(NULLIF(m.formaPago, ''), 'N/A') AS formaPago,
    m.fechaCreacion

FROM 
    matriculas m 
JOIN 
    cursos c ON m.IdCurso = c.ID
JOIN 
    horarios_cursos HC ON HC.ID = m.IdHorario
WHERE 
    m.activa = 1
    AND m.fechaCreacion >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH);

";

$spanolSql = "

SET lc_time_names = 'es_ES';
";

$stmtMatriculas = $conn->prepare($matriculasSql);

$espanol = $conn->prepare($spanolSql);
$espanol->execute();
$stmtMatriculas->execute();
$result = $stmtMatriculas->get_result();

$matriculas = [];

// Recoger los resultados y almacenarlos en un array
while ($row = $result->fetch_assoc()) {
    $matriculas[] = $row;
}

// Cerrar la conexión a la base de datos
$stmtMatriculas->close();
$conn->close();

// Devolver la respuesta en formato JSON
http_response_code(200); // OK
echo json_encode($matriculas);
?>
