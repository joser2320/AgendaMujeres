<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el cursoID esté presente
if (!isset($data->cursoID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$cursoID = $data->cursoID;

// Preparar la llamada al procedimiento almacenado
$spSql = "CALL ObtenerHorariosCurso(?)";
$stmtHorarios = $conn->prepare($spSql);
$stmtHorarios->bind_param("i", $cursoID);

// Ejecutar el procedimiento almacenado
$stmtHorarios->execute();
$result = $stmtHorarios->get_result();

$horarios = [];

// Recoger los resultados y almacenarlos en un array
while ($row = $result->fetch_assoc()) {
    $horarios[] = $row;
}

// Cerrar la conexión a la base de datos
$stmtHorarios->close();
$conn->close();

// Devolver la respuesta en formato JSON
http_response_code(200); // OK
echo json_encode($horarios);
?>
