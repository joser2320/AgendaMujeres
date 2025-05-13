<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión y el id de usuario estén presentes
if (!isset($data->usuarioID) || !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$usuarioID = $data->usuarioID;
$tokenSesion = $data->tokenSesion;

// Validar que el usuarioID no sea 1
if ($usuarioID == 1) {
    http_response_code(403); // Forbidden
    echo json_encode(["mensaje" => "No se puede eliminar el usuario con ID 1 (administrador)"]);
    exit;
}

// Validar que la sesión esté activa
$sessionSql = "SELECT * FROM sesiones WHERE TokenSesion = ? AND FechaFin > NOW()";
$stmt = $conn->prepare($sessionSql);

// Verificar si la preparación fue exitosa
if ($stmt === false) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al preparar la consulta de sesión", "error" => $conn->error]);
    exit;
}

$stmt->bind_param("s", $tokenSesion);
$stmt->execute();
$sessionResult = $stmt->get_result();

// Si no se encuentra la sesión activa, retornar error
if ($sessionResult->num_rows == 0) {
    http_response_code(401); // Unauthorized
    echo json_encode(["mensaje" => "Sesión no válida o expirada", "codigo" => -1]);
    exit;
}

// Validar que el usuarioID no esté vacío
if (empty($usuarioID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El ID de usuario es obligatorio"]);
    exit;
}

// Iniciar una transacción para asegurarse de que todas las operaciones sean atómicas
$conn->begin_transaction();

try {
    // Eliminar el usuario de la tabla USUARIOS
    $deleteUserSql = "DELETE FROM usuarios WHERE ID = ?";
    $stmt = $conn->prepare($deleteUserSql);
    
    // Verificar si la preparación fue exitosa
    if ($stmt === false) {
        throw new Exception("Error al preparar la consulta para eliminar usuario: " . $conn->error);
    }

    $stmt->bind_param("i", $usuarioID);

    if (!$stmt->execute()) {
        throw new Exception("Error al eliminar el usuario.");
    }

    // Eliminar todas las sesiones del usuario de la tabla SESIONES
    $deleteSessionsSql = "DELETE FROM sesiones WHERE UsuarioID = ?";
    $stmt = $conn->prepare($deleteSessionsSql);
    
    // Verificar si la preparación fue exitosa
    if ($stmt === false) {
        throw new Exception("Error al preparar la consulta para eliminar sesiones: " . $conn->error);
    }

    $stmt->bind_param("i", $usuarioID);

    if (!$stmt->execute()) {
        throw new Exception("Error al eliminar las sesiones del usuario.");
    }

    // Eliminar todos los roles del usuario de la tabla ROLES
    $deleteRolesSql = "DELETE FROM usuarios_roles WHERE UsuarioID = ?";
    $stmt = $conn->prepare($deleteRolesSql);
    
    // Verificar si la preparación fue exitosa
    if ($stmt === false) {
        throw new Exception("Error al preparar la consulta para eliminar roles: " . $conn->error);
    }

    $stmt->bind_param("i", $usuarioID);

    if (!$stmt->execute()) {
        throw new Exception("Error al eliminar los roles del usuario.");
    }

    // Si todo fue exitoso, hacer commit de la transacción
    $conn->commit();

    // Retornar respuesta indicando que el usuario fue eliminado con éxito
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "Usuario y sus datos eliminados exitosamente"]);

} catch (Exception $e) {
    // En caso de error, hacer rollback de la transacción
    $conn->rollback();

    // Retornar mensaje de error
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => $e->getMessage()]);
}

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
