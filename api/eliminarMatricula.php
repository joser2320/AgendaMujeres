<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el ID de matrícula y el token de sesión estén presentes
if (!isset($data->matriculaID) || !isset($data->tokenSesion)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$matriculaID = $data->matriculaID;
$tokenSesion = $data->tokenSesion;

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

// Validar que el matriculaID no esté vacío
if (empty($matriculaID)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El ID de matrícula es obligatorio"]);
    exit;
}

// Iniciar una transacción para asegurarse de que todas las operaciones sean atómicas
$conn->begin_transaction();

try {
    // Eliminar la matrícula de la tabla matriculas
    $deleteMatriculaSql = "DELETE FROM matriculas WHERE Id = ?";
    $stmt = $conn->prepare($deleteMatriculaSql);
    
    // Verificar si la preparación fue exitosa
    if ($stmt === false) {
        throw new Exception("Error al preparar la consulta para eliminar matrícula: " . $conn->error);
    }

    $stmt->bind_param("i", $matriculaID);

    if (!$stmt->execute()) {
        throw new Exception("Error al eliminar la matrícula.");
    }

    // Si todo fue exitoso, hacer commit de la transacción
    $conn->commit();

    // Retornar respuesta indicando que la matrícula fue eliminada con éxito
    http_response_code(200); // OK
    echo json_encode(["mensaje" => "Matrícula eliminada exitosamente"]);

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
