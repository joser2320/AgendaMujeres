<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->tokenSesion) || !isset($data->cursoID) || !isset($data->NombreCurso) || !isset($data->Descripcion) || !isset($data->FechaInicio) || !isset($data->FechaFin)|| !isset($data->Precio)|| !isset($data->ProcentajeProfesor)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$tokenSesion = $data->tokenSesion;
$cursoID = $data->cursoID;
$nombreCurso = $data->NombreCurso;
$descripcion = $data->Descripcion;
$fechaInicio = $data->FechaInicio;
$fechaFin = $data->FechaFin;
$ProcentajeProfesor = $data->ProcentajeProfesor;
$Precio = $data->Precio;

// Validar que los campos no estén vacíos
if (empty($tokenSesion) || empty($cursoID) || empty($nombreCurso) || empty($descripcion) || empty($fechaInicio) || empty($fechaFin)|| empty($Precio)|| empty($ProcentajeProfesor) ) {
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

// Actualizar el curso en la base de datos
$updateCursoSql = "UPDATE cursos SET NombreCurso = ?, Descripcion = ?, FechaInicio = ?, FechaFin = ?, Precio = ?, PorcentajePagoProfe = ? WHERE ID = ?;
";
$stmt = $conn->prepare($updateCursoSql);
$stmt->bind_param("ssssdii", $nombreCurso, $descripcion, $fechaInicio, $fechaFin,$Precio,$ProcentajeProfesor, $cursoID);

if ($stmt->execute()) {
    // Respuesta exitosa
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "Curso actualizado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al actualizar el curso"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
