function deleteUser(usuarioID) {
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
                usuarioID: usuarioID,
                tokenSesion: tokenSesion
            };

            // Hacer la solicitud de eliminación al API
            fetch('https://cursomujerescr.com/api/deleteUser.php', {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            })
            .then(response => {
                if (response.ok) {  // Si la respuesta es 2xx
                    return response.json();
                }
                throw new Error('Error al eliminar el usuario');
            })
            .then(() => {
                Swal.fire({
                    icon: 'success',
                    title: '¡Usuario eliminado!',
                    text: 'El usuario ha sido eliminado correctamente.',
                }).then(() => {
                    // Recargar la página después de la eliminación exitosa
                    location.reload();
                });
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
