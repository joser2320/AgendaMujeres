// Función para abrir el modal
function openMovementModalPagarProfe(pago) {
    document.getElementById('montoPagoProfe').textContent = pago;
    $('#crearMovimientoModal').modal('show'); // Cambia 'crearMovimientoModal' al ID de tu modal
}

// Función para cerrar el modal
function closeMovementModalPagarProfe() {
    $('#crearMovimientoModal').modal('hide'); // Cambia 'crearMovimientoModal' al ID de tu modal
}

// Función para enviar el formulario de registro de movimiento
async function submitMovementProfesorForm() {
    // Obtener los valores del formulario
    const courseId = getUrlParameter('IdCurso'); // Obtener el idCurso de la URL
    const notes = document.getElementById('notasProfesor').value; // Obtener las notas
    const receipt = document.getElementById('comprobanteProfesor').value; // Obtener el comprobante
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Obtener el token de sesión
    const IdPago = getUrlParameter('IdPago'); 
    const monto = document.getElementById('montoPagoProfe').value;
    const IdProfe = getUrlParameter('idProfesor'); 

    // Preguntar al usuario si está seguro de no agregar más información
    if (!notes && !receipt) {
        const userConfirmation = await Swal.fire({
            title: '¿Estás seguro?',
            text: '¿Deseas continuar sin agregar más información?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sí, continuar',
            cancelButtonText: 'No, volver'
        });

        if (!userConfirmation.isConfirmed) {
            return; // Si el usuario cancela, no se envía el formulario
        }
    }

    // Crear el cuerpo de la solicitud en formato JSON
    const requestBody = {
        IdCurso: parseInt(courseId, 10),
        IdProfesor: IdProfe,
        notas: notes,
        comprobante: receipt,
        monto: parseFloat(monto),
        tokenSesion: tokenSesion,
        IdPago:IdPago
    };

    // Enviar la solicitud a la API
    try {
        const response = await fetch('http://127.0.0.1/api/InsertarMovimientoEgreso.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        });

        // Verificar el código de respuesta HTTP (201 Created)
        if (response.status === 201) {
            const data = await response.json();
            // Mostrar alerta de éxito si el movimiento se registró correctamente
            Swal.fire({
                icon: 'success',
                title: 'Pago Registrado correctamente',
                text: data.mensaje // Mensaje de éxito desde la respuesta
            }).then(() => {
                // Limpiar los campos del formulario después de la respuesta
                document.getElementById('movementForm').reset();
                closeMovementModalPagarProfe(); // Cerrar el modal al crear exitosamente

                // Redirigir a la página de contabilidad
                window.location.href = 'contabilidad.html'; // Cambia esta URL a la página de contabilidad
            });
        } else {
            // Si el código HTTP no es 201, mostrar mensaje de error
            const data = await response.json();
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: data.mensaje || 'Ocurrió un error al registrar el movimiento.'
            });
        }
    } catch (error) {
        console.error('Error:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Ocurrió un error al intentar registrar el movimiento.'
        });
    }
}

// Llama a esta función para abrir el modal en algún evento, como un botón
document.getElementById('openModalButton').onclick = openMovementModalPagarProfe; // Asegúrate de que el botón tenga este ID
