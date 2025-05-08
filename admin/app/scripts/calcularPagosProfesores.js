// Función para enviar solo el token de sesión a la API
async function CalcularPagosPorProfesor() {
    const url = 'http://127.0.0.1/api/calcularPagosProfesores.php';  // URL de la API

    // Obtener el token de sesión de sessionStorage
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    // Validar que el token de sesión no esté vacío
    if (!tokenSesion) {
        Swal.fire({
            icon: 'error',
            title: 'Token de Sesión No Encontrado',
            text: 'Por favor, inicia sesión para continuar.',
        });
        return;  // Detener la ejecución si el token de sesión está vacío
    }

    // Objeto con el token de sesión para enviar a la API
    const body = {
        tokenSesion: tokenSesion
    };

    try {
        // Enviar la solicitud POST a la API
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        if (!response.ok) {
            throw new Error(`Error: ${response.statusText}`);
        }

        // Obtener la respuesta de la API
        const data = await response.json();

        // Verificar si la respuesta tiene un mensaje de éxito
        const mensaje = data.mensaje || "Operación completada exitosamente"; // Usar un valor predeterminado si no existe "mensaje"

        // Mostrar el mensaje de éxito con SweetAlert2
        Swal.fire({
            icon: 'success',
            title: mensaje,
        }).then(() => {
            // Recargar la página después de que el usuario cierre la alerta de éxito
            location.reload();
        });

    } catch (error) {
        // Manejo de errores
        console.error('Error al realizar la operación:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Hubo un problema al realizar la operación. Inténtalo de nuevo.',
        });
    }
}
