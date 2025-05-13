<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->idUsuario)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar el valor de idUsuario
$idUsuario = $data->idUsuario;

// Validar que no esté vacío
if (empty($idUsuario)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El ID de usuario es obligatorio"]);
    exit;
}

// Eliminar todas las sesiones del usuario de la tabla SESIONES
$deleteSql = "DELETE FROM sesiones WHERE UsuarioID = ?";
$stmt = $conn->prepare($deleteSql);
$stmt->bind_param("i", $idUsuario);

// Ejecutar la eliminación de sesiones
if (!$stmt->execute()) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al cerrar la sesión"]);
    exit;
}

// Retornar respuesta indicando que el logout fue exitoso
http_response_code(200); // OK
echo json_encode([
    "mensaje" => "Sesión cerrada exitosamente"
]);

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
