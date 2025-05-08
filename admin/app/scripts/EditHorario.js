// Función para enviar el formulario de creación de horario
async function submitEditScheduleForm() {
    // Obtener los valores del formulario

    const cupo = document.getElementById('cupoEdit').value;
    const professorId = document.getElementById('professorEdit').value; // Obtener el id del profesor desde el combobox
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Obtener el token de sesión
    const HorarioId = document.getElementById('HorarioId').value;

    // Validar que los campos obligatorios estén llenos
    if (!professorId || !cupo) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Por favor, completa todos los campos.'
        });
        return;
    }

    // Crear el cuerpo de la solicitud en formato JSON
    const requestBody = {
        tokenSesion: tokenSesion,
        IdHorario: parseInt(HorarioId),
        IdProfesor: parseInt(professorId), // Usamos el id del profesor del combobox
        Cupo: parseInt(cupo, 10)
    };

    // Enviar la solicitud a la API
    try {
        const response = await fetch('http://127.0.0.1/api/editHorario.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        });

        // Verificar el código de respuesta HTTP (200 OK)
        if (response.ok) {
            const data = await response.json();
            // Manejar el código de respuesta de la API
            if (data.codigo === "0") {
                // Mostrar alerta de éxito si el horario se creó correctamente
                Swal.fire({
                    icon: 'success',
                    title: 'Éxito',
                    text: data.mensaje // Mensaje de éxito desde la respuesta
                }).then(() => {
                    // Limpiar los campos del formulario después de la respuesta
                    document.getElementById('createScheduleForm').reset();
                    closeModal('EditScheduleModal'); // Cerrar el modal al crear exitosamente
                });
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: data.mensaje // Mensaje de error desde la respuesta
                });
            }
        } else {
            // Si el código HTTP no es 200, mostrar mensaje de error
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: `Hubo un problema con la solicitud. Código HTTP: ${response.status}.`
            });
        }
    } catch (error) {
        console.error('Error:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Ocurrió un error al intentar crear el horario.'
        });
    }
}
