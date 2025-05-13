<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->tokenSesion) || !isset($data->cursoID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$tokenSesion = $data->tokenSesion;
$cursoID = $data->cursoID;

// Validar que los campos no estén vacíos
if (empty($tokenSesion) || empty($cursoID)) {
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

// Eliminar el curso de la base de datos
$deleteCursoSql = "DELETE FROM cursos WHERE ID = ?";
$stmt = $conn->prepare($deleteCursoSql);
$stmt->bind_param("i", $cursoID);

if ($stmt->execute()) {
    // Respuesta exitosa
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "Curso eliminado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al eliminar el curso"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
