<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->token) || !isset($data->nombreCurso) || !isset($data->descripcion) || !isset($data->fechaInicio) || !isset($data->fechaFin)  || !isset($data->precio) || !isset($data->PorcentajePagoProfe)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$tokenSesion = $data->token;
$nombreCurso = $data->nombreCurso;
$descripcion = $data->descripcion;
$fechaInicio = $data->fechaInicio;
$fechaFin = $data->fechaFin;
$precio = $data->precio;
$porcentajeProfe = $data->PorcentajePagoProfe;
$cantidadCuotasCurso = $data->cantidadCuotasCurso;


// Validar que los campos no estén vacíos
if (empty($tokenSesion) || empty($nombreCurso) || empty($descripcion) || empty($fechaInicio) || empty($fechaFin)|| empty($precio)|| empty($porcentajeProfe)) {
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
    echo json_encode(["mensaje" => "Sesión no válida o expirada", "codigo"  => -1]);
    exit;
}

// Insertar el curso en la base de datos
$insertCursoSql = "INSERT INTO cursos (NombreCurso, Descripcion, FechaInicio, FechaFin, Precio,PorcentajePagoProfe,cantidadCuotas) VALUES (?, ?, ?, ?,?, ?,?)";
$stmt = $conn->prepare($insertCursoSql);
$stmt->bind_param("ssssdii", $nombreCurso, $descripcion, $fechaInicio, $fechaFin,$precio, $porcentajeProfe,$cantidadCuotasCurso);

if ($stmt->execute()) {
    // Respuesta exitosa
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Curso registrado exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al registrar el curso"]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
