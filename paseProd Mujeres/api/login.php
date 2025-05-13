<?php
header("Access-Control-Allow-Origin: *"); // Permite todas las fuentes. Usa el dominio específico en producción.
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
// Incluir el archivo de conexión a la base de datos
include 'db.php';

// Definir el tipo de respuesta como JSON
header('Content-Type: application/json');

// Obtener los datos enviados a través de la API (en formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Verificar que los datos estén presentes
if (!isset($data->email) || !isset($data->password)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "Faltan campos obligatorios"]);
    exit;
}

// Asignar los valores a variables
$email = $data->email;
$password = $data->password;

// Validar que no estén vacíos
if (empty($email) || empty($password)) {
    http_response_code(400); // Bad Request
    echo json_encode(["mensaje" => "El correo y la contraseña son obligatorios"]);
    exit;
}

// Verificar si el correo existe en la base de datos
$sql = "SELECT * FROM usuarios WHERE Email = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

// Si no se encuentra el usuario, retornar error
if ($result->num_rows == 0) {
    http_response_code(401); // Unauthorized
    echo json_encode(["mensaje" => "Credenciales incorrectas"]);
    exit;
}

// Obtener los datos del usuario
$user = $result->fetch_assoc();

// Verificar si la contraseña coincide
if (!password_verify($password, $user['Password'])) {
    http_response_code(401); // Unauthorized
    echo json_encode(["mensaje" => "Credenciales incorrectas"]);
    exit;
}

// Si el usuario está inactivo
if ($user['IsActive'] == 0) {
    http_response_code(403); // Forbidden
    echo json_encode(["mensaje" => "El usuario está deshabilitado"]);
    exit;
}

// Ejecutar la consulta para obtener los roles del usuario
$rolesSql = "
    SELECT 
        u.ID,
        u.Email,
        u.FullName,
        u.IsActive,
        -- Verificamos si el usuario tiene el rol de Administrador
        IF(SUM(r.RoleName = 'Administrador'), 1, 0) AS Administrador,
        -- Verificamos si el usuario tiene el rol de Servicio al Cliente
        IF(SUM(r.RoleName = 'Servicio al cliente'), 1, 0) AS ServicioAlCliente,
        -- Verificamos si el usuario tiene el rol de Contable
        IF(SUM(r.RoleName = 'Contable'), 1, 0) AS Contable,
        -- Verificamos si el usuario tiene el rol de Reportería
        IF(SUM(r.RoleName = 'Reporteria'), 1, 0) AS Reporteria
    FROM 
        usuarios u
    LEFT JOIN 
        usuarios_roles ru ON u.ID = ru.UsuarioID
    LEFT JOIN 
        roles r ON ru.RoleID = r.ID
    WHERE 
        u.ID = ?
    GROUP BY 
        u.ID, u.Email, u.FullName, u.IsActive";

// Preparar y ejecutar la consulta para roles
$stmt = $conn->prepare($rolesSql);
$stmt->bind_param("i", $user['ID']);
$stmt->execute();
$rolesResult = $stmt->get_result();

// Obtener los roles del usuario
$rolesData = $rolesResult->fetch_assoc();

// Generar un token de sesión (puedes usar un algoritmo como UUID o JWT)
$token = bin2hex(random_bytes(16)); // Token de 32 caracteres

// Obtener la fecha de fin (una hora después de la fecha actual)
$fechaFin = date('Y-m-d H:i:s', strtotime('+1 hour'));

// Eliminar cualquier sesión activa previa para este usuario
$deleteSql = "DELETE FROM sesiones WHERE UsuarioID = ?";
$stmt = $conn->prepare($deleteSql);
$stmt->bind_param("i", $user['ID']);
$stmt->execute();

// Insertar la nueva sesión en la base de datos
$sessionSql = "INSERT INTO sesiones (UsuarioID, TokenSesion, FechaFin) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sessionSql);
$stmt->bind_param("iss", $user['ID'], $token, $fechaFin);

if (!$stmt->execute()) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["mensaje" => "Error al crear la sesión"]);
    exit;
}

// Retornar respuesta con el token de sesión y los roles del usuario
http_response_code(200); // OK
echo json_encode([
    "mensaje" => "Inicio de sesión exitoso",
    "tokenSesion" => $token,
    "usuario" => [
        "id" => $user['ID'],
        "email" => $user['Email'],
        "fullName" => $user['FullName'],
        "isActive" => $user['IsActive'],
        "roles" => [
            "Administrador" => $rolesData['Administrador'],
            "ServicioAlCliente" => $rolesData['ServicioAlCliente'],
            "Contable" => $rolesData['Contable'],
            "Reporteria" => $rolesData['Reporteria']
        ]
    ]
]);

// Cerrar la conexión
$stmt->close();
$conn->close();
?>
