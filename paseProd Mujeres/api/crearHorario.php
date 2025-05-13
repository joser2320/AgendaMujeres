<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que todos los datos requeridos estén presentes
if (!isset($data->tokenSesion) || !isset($data->DiaSemana) || !isset($data->HoraInicio) || !isset($data->HoraFin) || !isset($data->IdCurso) || !isset($data->IdProfesor) || !isset($data->Cupo)) {
    http_response_code(400); // Bad Request
    echo json_encode(["codigo" => -1, "mensaje" => "Faltan datos requeridos"]);
    exit;
}

// Asignar los datos a variables
$tokenSesion = $data->tokenSesion;
$DiaSemana = $data->DiaSemana;
$HoraInicio = $data->HoraInicio;
$HoraFin = $data->HoraFin;
$IdCurso = $data->IdCurso;
$IdProfesor = $data->IdProfesor;
$Cupo = $data->Cupo;

// Verificar si la sesión es válida en la base de datos
$sql = "SELECT * FROM sesiones WHERE TokenSesion = ? AND FechaFin > NOW()";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $tokenSesion);
$stmt->execute();
$result = $stmt->get_result();

// Si no se encuentra una sesión activa
if ($result->num_rows == 0) {
    http_response_code(401); // Unauthorized
    echo json_encode(["codigo" => -1, "mensaje" => "Sesión no válida o expirada"]);
    exit;
}

// Llamar al procedimiento almacenado para validar la combinación de horario y profesor
$sp = "CALL ValidarYInsertarHorario(?, ?, ?, ?, ?, ?, @resultado, @mensaje)";
$stmt_sp = $conn->prepare($sp);
$stmt_sp->bind_param("sssiii", $DiaSemana, $HoraInicio, $HoraFin, $IdCurso, $IdProfesor, $Cupo);
$stmt_sp->execute();

// Obtener el resultado y el mensaje de la ejecución del procedimiento almacenado
$result_sp = $conn->query("SELECT @resultado AS codigo, @mensaje AS mensaje");
$row = $result_sp->fetch_assoc();

// Retornar el resultado y el mensaje
echo json_encode(["codigo" => $row['codigo'], "mensaje" => $row['mensaje']]);

$stmt_sp->close();
$conn->close();
?>
