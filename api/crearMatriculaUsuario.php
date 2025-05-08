<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Establecer la zona horaria en PHP
date_default_timezone_set('America/Costa_Rica');

// Configurar la zona horaria en MySQL
$conn->query("SET time_zone = '-6:00'");

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->nombreEstudiante) || !isset($data->cedula) || !isset($data->telefono) || 
    !isset($data->correo) || !isset($data->estadoPago) || 
    !isset($data->idCurso) || !isset($data->idHorario) ) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$nombreEstudiante = $data->nombreEstudiante;
$cedula = $data->cedula;
$telefono = $data->telefono;
$correo = $data->correo;
$estadoPago = $data->estadoPago;
$comprobante = $data->Comprobante;
$idCurso = (int)$data->idCurso;
$idHorario = (int)$data->idHorario;
$tokenSesion = $data->tokenSesion;

// Validar que no estén vacíos
if (empty($nombreEstudiante) || empty($cedula) || empty($telefono) || 
    empty($correo) || empty($estadoPago) ) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Todos los campos son obligatorios"]);
    exit;
}

// Validar que idCurso y idHorario sean enteros válidos
if (!is_int($idCurso) || $idCurso <= 0) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El ID del curso debe ser un entero positivo"]);
    exit;
}

if (!is_int($idHorario) || $idHorario <= 0) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El ID del horario debe ser un entero positivo"]);
    exit;
}

// Verificar si ya existe una matrícula con la misma cédula y curso
$checkSql = "SELECT * FROM matriculas WHERE Cedula = ? AND IdCurso = ?";
$stmt = $conn->prepare($checkSql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar la consulta de verificación de matrícula: " . $conn->error]);
    exit;
}
$stmt->bind_param("si", $cedula, $idCurso);
$stmt->execute();
$checkResult = $stmt->get_result();

if ($checkResult->num_rows > 0) {
    http_response_code(409); // Conflict
    echo json_encode(["mensaje" => "Ya existe una matrícula con la misma cédula en este curso"]);
    exit;
}

// Obtener 'cantidadCuotas' del curso y asignarlo a 'cuotasPendientes'
$selectSql = "SELECT cantidadCuotas FROM cursos WHERE ID = ?";
$stmt = $conn->prepare($selectSql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar la consulta de selección de curso: " . $conn->error]);
    exit;
}
$stmt->bind_param("i", $idCurso);
$stmt->execute();
$stmt->bind_result($cuotasPendientes);
$stmt->fetch();
$stmt->close();

if ($cuotasPendientes === null) {
    http_response_code(404); // Not Found
    echo json_encode(["mensaje" => "Curso no encontrado"]);
    exit;
}

// Insertar datos en la tabla 'matriculas' usando el valor de 'cuotasPendientes'
$insertSql = "INSERT INTO matriculas (Nombre, Cedula, Telefono, Correo, estadoPago, comprobante, IdCurso, IdHorario, cuotasPendientes, fechaCreacion) 
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
$stmt = $conn->prepare($insertSql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["mensaje" => "Error al preparar la consulta de inserción de matrícula: " . $conn->error]);
    exit;
}
$stmt->bind_param("ssssssiii", $nombreEstudiante, $cedula, $telefono, $correo, $estadoPago, $comprobante, $idCurso, $idHorario, $cuotasPendientes);

if ($stmt->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Matrícula creada exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al crear la matrícula"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
