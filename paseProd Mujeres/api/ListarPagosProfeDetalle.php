<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el ID de curso y el token de sesión estén presentes
if (!isset($data->idCurso) || !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a las variables
$idCurso = $data->idCurso;
$IdProfesor = $data->IdProfesor;

$tokenSesion = $data->tokenSesion; // Token de sesión

// Validar que no estén vacíos
if (empty($idCurso) || empty($tokenSesion)) {
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

// Llamar al procedimiento almacenado para obtener los detalles de pago
$detailsSql = "select * from listapagosprofesor where idCurso =? and idProfesor = ?";
$stmt = $conn->prepare($detailsSql);
$stmt->bind_param("ii", $idCurso,$IdProfesor);

// Ejecutar el procedimiento almacenado
if ($stmt->execute()) {
    // Obtener los resultados
    $result = $stmt->get_result();
    $detalles = [];
    $totalMonto = 0; // Variable para almacenar la suma total

    // Recoger todos los registros en un array y calcular la suma
    while ($row = $result->fetch_assoc()) {
        $detalles[] = $row;
        $totalMonto += floatval($row['TotalPagar']); // Sumar el monto
    }

    // Verificar si hay resultados
    if (count($detalles) > 0) {
        http_response_code(200); // OK
        echo json_encode([
            "detalles" => $detalles,
            "totalMonto" => number_format($totalMonto, 2, '.', '') // Retornar el total con punto como separador decimal y sin separador de miles
        ]);
    } else {
        http_response_code(404); // Not Found
        echo json_encode(["mensaje" => "No se encontraron detalles de pago para el curso especificado"]);
    }
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al obtener los detalles de pago"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
