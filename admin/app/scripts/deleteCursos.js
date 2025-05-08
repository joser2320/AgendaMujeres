// Función para eliminar un curso
function deleteCurso(cursoID) {
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
                cursoID: cursoID,
                tokenSesion: tokenSesion
            };

            // Hacer la solicitud de eliminación al API
            fetch('http://127.0.0.1/api/DeleteCurso.php', {
                method: 'POST',  // La API puede requerir un POST en lugar de DELETE
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            })
            .then(response => {
                if (response.status === 200) {  // Verificar si el status HTTP es 200
                    return response.json();
                }
                throw new Error('Error al eliminar el curso');
            })
            .then((data) => {
                Swal.fire({
                    icon: 'success',
                    title: '¡Curso eliminado!',
                    text: data.mensaje || 'El curso ha sido eliminado correctamente.',
                }).then(() => {
                    // Recargar la página después de la eliminación exitosa
                    location.reload();
                });
            })
            .catch((error) => {
                console.error('Error:', error);  // Mostrar el error en consola
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'No se pudo eliminar el curso.',
                });
            });
        }
    });
}
