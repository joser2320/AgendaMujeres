<?php
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que el token de sesión esté presente
if (!isset($data->token)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

$tokenSesion = $data->token;

// Validar que la sesión esté activa
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

// Obtener el ID del usuario asociado al token
$sessionData = $sessionResult->fetch_assoc();
$idUsuario = $sessionData['UsuarioID']; // Asumiendo que la columna UsuarioID está en la tabla SESIONES

// Preparar la consulta para obtener todos los usuarios y sus roles desde la vista
$sql = "SELECT UsuarioID, Email, FullName, IsActive, 
                Administrador, Servicio_al_cliente, Contable, Reporteria
        FROM vista_usuarios_roles where UsuarioID <> 1 and UsuarioID <>2";

// Preparar la declaración
$stmt = $conn->prepare($sql);

// Verificar que la preparación fue exitosa
if ($stmt === false) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al preparar la consulta"]);
    exit;
}

// Ejecutar la consulta
$stmt->execute();

// Obtener el resultado
$result = $stmt->get_result();

// Verificar si hay usuarios
if ($result->num_rows == 0) {
    http_response_code(404); // Not Found
    echo json_encode(["mensaje" => "No se encontraron usuarios"]);
    exit;
}

// Inicializar un array para los usuarios
$usuarios = [];

// Recorrer los resultados y agregar cada usuario al array
while ($userData = $result->fetch_assoc()) {
    $usuarios[] = [
        "UsuarioID" => $userData['UsuarioID'],
        "Email" => $userData['Email'],
        "FullName" => $userData['FullName'],
        "IsActive" => $userData['IsActive'],
        "Roles" => [
            "Administrador" => $userData['Administrador'],
            "Servicio al cliente" => $userData['Servicio_al_cliente'],
            "Contable" => $userData['Contable'],
            "Reporteria" => $userData['Reporteria']
        ]
    ];
}

// Retornar la respuesta con todos los usuarios y sus roles
http_response_code(200); // OK
echo json_encode($usuarios);

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
