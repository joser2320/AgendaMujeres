// Función para abrir el modal y consultar los horarios disponibles
async function openMatriculaModal(courseId) {
    document.getElementById('idCursoMatricular').value = courseId;

    // Consulta los horarios disponibles
    const horarios = await obtenerHorarios(courseId);
    const horarioSelect = document.getElementById('horarioSelect');

    // Limpiar horarios previos
    horarioSelect.innerHTML = '<option value="" disabled selected>Selecciona un horario...</option>'; // Opción por defecto

    // Filtrar horarios con cupo restante mayor a cero
    const horariosDisponibles = horarios.filter(horario => horario.CupoRestante > 0);

    if (horariosDisponibles.length > 0) {
        horariosDisponibles.forEach(horario => {
            const option = document.createElement('option');
            option.value = horario.idHorario;
            option.textContent = `${horario.Dia} - ${horario.HoraInicio} a ${horario.HoraFin} (Profesor: ${horario.Profesor}) - Cupo Restante: ${horario.CupoRestante}`;
            horarioSelect.appendChild(option);
        });
    } else {
        const option = document.createElement('option');
        option.value = '';
        option.textContent = 'No hay horarios disponibles.';
        horarioSelect.appendChild(option);
        horarioSelect.disabled = true; // Deshabilitar si no hay horarios
    }

    // Muestra el modal
    $('#crearMatriculaModal').modal('show');
}

// Función para obtener los horarios disponibles
async function obtenerHorarios(cursoID) {
    try {
        const response = await fetch('http://127.0.0.1/api/listarHorarioCursoUsuario.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ cursoID: cursoID }),
        });

        if (!response.ok) {
            throw new Error('Error al obtener horarios');
        }

        const result = await response.json();
        return result; // Regresa la lista de horarios
    } catch (error) {
        console.error('Error:', error);
        Swal.fire('Error', 'No se pudieron obtener los horarios', 'error');
        return [];
    }
}

// Función para validar los campos del formulario
function validarCampos() {
    const form = document.getElementById('crearMatriculaForm');
    const horarioSelect = document.getElementById('horarioSelect');

    // Validar campos
    if (!horarioSelect.value) {
        Swal.fire('Advertencia', 'Por favor, selecciona un horario.', 'warning');
        return false;
    }
    if (!form.nombreEstudiante.value.trim()) {
        Swal.fire('Advertencia', 'Por favor, ingresa el nombre del estudiante.', 'warning');
        return false;
    }
    if (!form.cedulaEstudiante.value.trim()) {
        Swal.fire('Advertencia', 'Por favor, ingresa la cédula del estudiante.', 'warning');
        return false;
    }
    if (!form.telefonoEstudiante.value.trim()) {
        Swal.fire('Advertencia', 'Por favor, ingresa el teléfono del estudiante.', 'warning');
        return false;
    }
    if (!form.correoEstudiante.value.trim()) {
        Swal.fire('Advertencia', 'Por favor, ingresa el correo electrónico del estudiante.', 'warning');
        return false;
    }
    if (!form.numeroComprobante.value.trim()) {
        Swal.fire('Advertencia', 'Por favor, ingresa comprobante del pago.', 'warning');
        return false;
    }

    return true; // Todos los campos son válidos
}

// Función para crear la matrícula
async function crearMatricula() {
    if (!validarCampos()) {
        return; // Detener si los campos no son válidos
    }

    const form = document.getElementById('crearMatriculaForm');
    const formData = new FormData(form);
    const data = {
        idCurso: formData.get('idCursoMatricular'),
        idHorario: formData.get('horario'), // Se obtiene el horario seleccionado
        nombreEstudiante: formData.get('nombreEstudiante'),
        cedula: formData.get('cedulaEstudiante'),
        telefono: formData.get('telefonoEstudiante'),
        correo: formData.get('correoEstudiante'),
        estadoPago: 'Pendiente',
        formaPago: formData.get('metodoPago'), // Captura el método de pago seleccionado
        Comprobante: formData.get('numeroComprobante') // Captura el comprobante si está disponible
    };

    try {
        const response = await fetch('http://127.0.0.1/api/crearMatriculaUsuario.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });

        if (!response.ok) {
            if (response.status === 500) {
                throw new Error('Se presentó un problema de comunicación al intentar matricular. Por favor intente de nuevo.');
            } else if (response.status === 409) {
                throw new Error('La matrícula no se puede llevar a cabo. Es posible que el número de cédula ya esté registrado para este curso. Por favor comuníquese con servicio al cliente para verificar la matricula en caso de tener dudas.');
            }
            const result = await response.json();
            throw new Error(result.mensaje);
        }

        const result = await response.json();

        // Llamada a la función de notificación antes de mostrar el SweetAlert
        await notificarCreacionMatricula(data.telefono, data.nombreEstudiante);

        // Mostrar SweetAlert de éxito solo después de la notificación
        Swal.fire({
            title: 'Matrícula creada correctamente.',
            icon: 'success',
            confirmButtonText: 'OK'
        }).then(() => {
            closeModal('crearMatriculaModal'); // Cierra el modal después de la creación
            window.location.reload(); // Recarga la página si la matrícula se crea correctamente
        });

        loadCourses(); // Opcional: recargar cursos si es necesario
    } catch (error) {
        console.error('Error:', error);
        Swal.fire('Error', error.message, 'error');
    }
}


// Función para enviar notificación de creación de matrícula
async function notificarCreacionMatricula(phone, studentName) {
    const mensaje = `Hola ${studentName}. Hemos recibido su solicitud de matrícula, pronto le informaremos por este medio cuando su pago fue confirmado.`;

    // 1️⃣ Preparar el cuerpo del mensaje para WhatsApp
    const whatsappRequestBody = {
        chatId: `${phone}@c.us`,
        message: mensaje
    };

    try {
        // 2️⃣ Enviar el mensaje por WhatsApp
        const whatsappResponse = await fetch('https://waapi.app/api/v1/instances/48511/client/action/send-message', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': `Bearer VqYXAVDiAFKAP1kRZmhonMLo3zdxmWObSS2upAm27fef1168`
            },
            body: JSON.stringify(whatsappRequestBody)
        });

        if (whatsappResponse.ok) {
            console.log("Mensaje de WhatsApp enviado exitosamente.");

            // 3️⃣ Si el mensaje fue enviado correctamente, registrar en la base de datos
            const dbRequestBody = {
                Envia: "Sistema",
                Recibe: phone,
                Mensaje: mensaje
            };

            const dbResponse = await fetch('http://127.0.0.1/api/RegistrarLogWhatsApp.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(dbRequestBody)
            });

            const dbResult = await dbResponse.json();

            if (dbResponse.ok) {
                console.log("Mensaje registrado en la base de datos correctamente.");
            } else {
                console.error("Error al registrar el mensaje en la base de datos:", dbResult.mensaje);
            }

        } else {
            console.error("Error al enviar el mensaje de WhatsApp.");
        }
    } catch (error) {
        console.error('Error en la notificación de matrícula:', error);
    }
}


// Función para cerrar el modal
function closeModal(modalId) {
    $(`#${modalId}`).modal('hide');
}
