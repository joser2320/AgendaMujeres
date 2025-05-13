function deleteMatricula(matriculaID) {
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
        text: "¡Esto no borrará los movimientos de dinero!",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sí, eliminar',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            const requestData = {
                matriculaID: matriculaID,
                tokenSesion: tokenSesion
            };

            // Hacer la solicitud de eliminación al API
            fetch('https://cursomujerescr.com/api/eliminarMatricula.php', {
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
                throw new Error('Error al eliminar la matrícula');
            })
            .then(() => {
                Swal.fire({
                    icon: 'success',
                    title: '¡Matrícula eliminada!',
                    text: 'La matrícula ha sido eliminada correctamente.',
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


function BorrarRegistrosMatricula(matriculaID) {
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
        text: "¡Todos los registros de la matricula, incluso los pagos ya reportados en el sistema serán borrados y no podrán ser revertidos!",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sí, eliminar',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            const requestData = {
                matriculaID: matriculaID,
                tokenSesion: tokenSesion
            };

            // Hacer la solicitud de eliminación al API
            fetch('https://cursomujerescr.com/api/eliminarRegistrosMatricula.php', {
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
                throw new Error('Error al eliminar la matrícula');
            })
            .then(() => {
                Swal.fire({
                    icon: 'success',
                    title: '¡Matrícula eliminada!',
                    text: 'La matrícula ha sido eliminada correctamente.',
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