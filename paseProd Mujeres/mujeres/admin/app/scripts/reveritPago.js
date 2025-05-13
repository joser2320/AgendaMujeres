function revertirPago(idMovimiento, idMatricula) {
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    // Verificar si hay token
    if (!tokenSesion) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se encontró un token de sesión válido.',
        });
        return;
    }

    // Confirmación de eliminación
    Swal.fire({
        title: '¿Estás seguro?',
        text: "Esta acción eliminará el movimiento y actualizará la matrícula.",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sí, eliminar',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            const requestData = {
                tokenSesion: tokenSesion,
                idMovimiento: idMovimiento,
                idMatricula: idMatricula
            };

            fetch('https://cursomujerescr.com/api/revertirPago.php', {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.codigo === 0) {
                    Swal.fire({
                        icon: 'success',
                        title: '¡Eliminado!',
                        text: data.mensaje,
                    }).then(() => {
                        location.reload();
                    });
                } else {
                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: data.mensaje,
                    });
                }
            })
            .catch(() => {
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Ocurrió un error al contactar el servidor.',
                });
            });
        }
    });
}
