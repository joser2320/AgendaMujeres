<?php
$host = "127.0.0.1";  // Dirección del servidor MySQL
$user = "u415516518_agenda_mujeres";       // Usuario de MySQL
$password = ":w*K3#d!&1E";       // Contraseña de MySQL (vacía por defecto en XAMPP)
$dbname = "u415516518_agenda_mujeres"; // Nombre de la base de datos

// Crear la conexión
$conn = new mysqli($host, $user, $password, $dbname);

// Verificar la conexión
if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}
?>
