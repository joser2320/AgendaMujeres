function actualizarMetodoPago() {
    const idMatricula = document.getElementById('idMatriculaUpdateMetodoPago').value;
    const metodoPago = document.getElementById('metodoPagoUpdate').value;
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    fetch('http://127.0.0.1/api/ActualizarMetodoPago.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            idMatricula: idMatricula,
            formaPago: metodoPago,
            tokenSesion: tokenSesion
        })
    })
    .then(response => {
        if (response.ok) {
            return response.json().then(data => {
                Swal.fire({
                    icon: 'success',
                    title: 'Método de Pago Actualizado',
                    text: data.mensaje || 'Actualización exitosa',
                    confirmButtonText: 'Aceptar'
                }).then(() => {
                    CloseModal('cambiarMetodoPagoModal');
                    location.reload(); // Recarga la página
                });
            });
        } else {
            return response.json().then(data => {
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: data.mensaje || 'Ocurrió un error al actualizar el método de pago',
                    confirmButtonText: 'Aceptar'
                });
            });
        }
    })
    .catch(error => {
        console.error('Error al actualizar el método de pago:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error de conexión',
            text: 'No se pudo actualizar el método de pago. Inténtalo nuevamente.',
            confirmButtonText: 'Aceptar'
        });
    });
}

function CloseModalUdpateMetodoPago(modalId) {
    $('#' + modalId).modal('hide');
}

function abrirModalUpdateMetodoPago(idMatricula) {
    document.getElementById('idMatriculaUpdateMetodoPago').value = idMatricula;
    $('#cambiarMetodoPagoModal').modal('show');
}
