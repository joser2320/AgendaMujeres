<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos obligatorios estén presentes: cursoID y urlImagen
if (!isset($data->cursoID) || !isset($data->urlImagen)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$cursoID = (int)$data->cursoID; // Convertir a entero
$urlImagen = $data->urlImagen; // URL de la imagen

// Validar que no estén vacíos
if (empty($cursoID) || empty($urlImagen)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El ID del curso y la URL de la imagen son obligatorios"]);
    exit;
}

// Eliminar cualquier registro existente para este cursoID antes de insertar el nuevo
$deleteSql = "DELETE FROM cursoimagen WHERE cursoID = ?";
$stmtDelete = $conn->prepare($deleteSql);
$stmtDelete->bind_param("i", $cursoID); // Vincular cursoID como entero
$stmtDelete->execute();
$stmtDelete->close(); // Cerrar la consulta después de eliminar

// Insertar los datos de la nueva imagen en la tabla `cursoimagen`
$insertSql = "INSERT INTO cursoimagen (cursoID, urlImagen, fechaCreacion) 
              VALUES (?, ?, NOW())"; // NOW() para la fecha actual
$stmtInsert = $conn->prepare($insertSql);
$stmtInsert->bind_param("is", $cursoID, $urlImagen); // i -> entero, s -> string

// Ejecutar la consulta e informar el resultado
if ($stmtInsert->execute()) {
    http_response_code(201); // Created
    echo json_encode(["mensaje" => "Imagen insertada exitosamente"]);
} else {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al insertar la imagen en la base de datos"]);
}

// Cerrar la conexión
$stmtInsert->close();
$conn->close();
?>
