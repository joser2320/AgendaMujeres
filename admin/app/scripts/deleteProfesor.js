function deleteProfesor(profesorID) {
    const tokenSesion = sessionStorage.getItem('tokenSesion');  // Usamos sessionStorage como ejemplo

    // Verificar si el token de sesión está presente
    if (!tokenSesion) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se encontró un token de sesión válido.',
        });
        return;
    }

    // Confirmar la eliminación
    Swal.fire({
        title: '¿Estás seguro?',
        text: "¡No podrás revertir esto!",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sí, eliminar',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            const requestData = {
                tokenSesion: tokenSesion,
                profesorID: profesorID
            };

            // Hacer la solicitud de eliminación al API
            fetch('http://127.0.0.1/api/deleteProfesor.php', {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            })
            .then(response => response.json())  // Procesar la respuesta como JSON
            .then(data => {
                // Verificar el código de respuesta del servidor
                if (data.codigo === -1) {
                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: data.mensaje, // Mostrar el mensaje de error de la API
                    });
                } else {
                    Swal.fire({
                        icon: 'success',
                        title: '¡Profesor eliminado!',
                        text: 'El profesor ha sido eliminado correctamente.',
                    }).then(() => {
                        // Recargar la página después de la eliminación exitosa
                        location.reload();
                    });
                }
            })
            .catch(() => {
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Hubo un error al realizar la solicitud. Por favor, intenta nuevamente.',
                });
            });
        }
    });
}
