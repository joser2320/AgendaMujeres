<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// No se requiere token de sesión, por lo que omitimos la validación de sesión

// Obtener los cursos activos desde la base de datos
$cursosSql = "SELECT * FROM vistacursosactivosv2";
$stmtCursos = $conn->prepare($cursosSql);
$stmtCursos->execute();
$result = $stmtCursos->get_result();

$cursos = [];

// Recoger los resultados y almacenarlos en un array
while ($row = $result->fetch_assoc()) {
    $cursos[] = $row;
}

// Cerrar la conexión a la base de datos
$stmtCursos->close();
$conn->close();

// Devolver la respuesta en formato JSON
http_response_code(200); // OK
echo json_encode($cursos);
?>
