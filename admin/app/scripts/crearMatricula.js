// Función para enviar el formulario de creación de matrícula
async function crearMatricula() {
    // Obtener los valores del formulario
    const courseId = document.getElementById('idCursoMatricular').value;
    const scheduleId = document.getElementById('idHorarioMatricular').value;
    const studentName = document.getElementById('nombreEstudiante').value;
    const cedula = document.getElementById('cedulaEstudiante').value;
    const phone = document.getElementById('telefonoEstudiante').value;
    const email = document.getElementById('correoEstudiante').value;
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    // Validar que los campos obligatorios estén llenos
    if (!studentName || !cedula || !phone || !email || !courseId || !scheduleId) {
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
        nombreEstudiante: studentName,
        cedula: cedula,
        telefono: phone,
        estadoPago: "Pendiente",
        correo: email,
        idCurso: parseInt(courseId, 10),
        idHorario: parseInt(scheduleId, 10)
    };

    try {
        // Enviar la solicitud a la API de creación de matrícula
        const response = await fetch('http://127.0.0.1/api/crearMatricula.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        });

        if (response.status === 201) {
            const data = await response.json();

            // Mostrar alerta de éxito para la creación de matrícula
            Swal.fire({
                icon: 'success',
                title: 'Éxito',
                text: data.mensaje
            }).then(async () => {
                // Limpiar los campos del formulario
                document.getElementById('crearMatriculaForm').reset();
                closeModal('crearMatriculaModal');

                // Llamar a la API de envío de mensaje de WhatsApp
                const whatsappRequestBody = {
                    chatId: `${phone}@c.us`,  // Número de teléfono con el formato requerido
                    message: `Hola ${studentName}. Hemos recibido su solicitud de matrícula, pronto le informaremos por este medio cuando su pago fue confirmado.`
                };

                try {
                    const whatsappResponse = await fetch('https://waapi.app/api/v1/instances/48511/client/action/send-message', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'Authorization': `Bearer VqYXAVDiAFKAP1kRZmhonMLo3zdxmWObSS2upAm27fef1168`
                        },
                        body: JSON.stringify(whatsappRequestBody)
                    });

                    // Verificar si el mensaje fue enviado correctamente
                    if (whatsappResponse.ok) {
                        console.log("Mensaje de WhatsApp enviado exitosamente.");
                    } else {
                        console.error("Error al enviar el mensaje de WhatsApp.");
                    }
                } catch (error) {
                    console.error('Error al enviar el mensaje de WhatsApp:', error);
                }
            });
        } else {
            const errorData = await response.json();
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: errorData.mensaje || `Hubo un problema con la solicitud. Código HTTP: ${response.status}.`
            });
        }
    } catch (error) {
        console.error('Error:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Ocurrió un error al intentar crear la matrícula.'
        });
    }
}
