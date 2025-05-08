// Función para enviar los datos del formulario y crear el curso
async function submitForm() {
    const url = 'http://127.0.0.1/api/crearCursos.php';  // URL de la API para crear el curso

    // Obtener los datos del formulario
    const nombreCurso = document.getElementById('nombreCurso').value;
    const descripcion = document.getElementById('descripcion').value;
    const fechaInicio = document.getElementById('fechaInicio').value;
    const fechaFin = document.getElementById('fechaFin').value;
    const CantidadCuotasCurso = document.getElementById('CantidadCuotasCurso').value;
    const precio = document.getElementById('precio').value.replace(/[^0-9.-]+/g,""); // Limpiar formato del precio
    const PorcentajePagoProfe = parseInt(document.getElementById('createPorcentajeProfe').value.replace(/[^0-9.-]+/g,"")); 

    // Obtener el token de sesión de sessionStorage
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    // Validar que los campos del formulario no estén vacíos
    if (!nombreCurso || !descripcion || !fechaInicio || !fechaFin || !tokenSesion || !precio|| !PorcentajePagoProfe|| !CantidadCuotasCurso) {
        Swal.fire({
            icon: 'error',
            title: 'Campos Incompletos',
            text: 'Por favor, complete todos los campos.',
        });
        return;  // Detener la ejecución si algún campo está vacío
    }

    // Validar que el precio sea un número válido
    const precioNum = parseFloat(precio);
    if (isNaN(precioNum) || precioNum <= 0) {
        Swal.fire({
            icon: 'error',
            title: 'Precio Inválido',
            text: 'Por favor, ingrese un precio válido.',
        });
        return;  // Detener la ejecución si el precio no es válido
    }

    // Validar que la fecha de inicio no sea en el pasado
    const fechaHoy = new Date().toISOString().split('T')[0];  // Obtener la fecha actual en formato YYYY-MM-DD
    if (fechaInicio < fechaHoy) {
        Swal.fire({
            icon: 'error',
            title: 'Fecha de Inicio Inválida',
            text: 'La fecha de inicio no puede ser en el pasado.',
        });
        return;  // Detener la ejecución si la fecha de inicio es en el pasado
    }

    // Validar que la fecha de fin no sea antes de la fecha de inicio
    if (fechaFin < fechaInicio) {
        Swal.fire({
            icon: 'error',
            title: 'Fecha de Fin Inválida',
            text: 'La fecha de fin no puede ser antes de la fecha de inicio.',
        });
        return;  // Detener la ejecución si la fecha de fin es antes de la fecha de inicio
    }

    // Objeto con los datos para enviar a la API
    const body = {
        token: tokenSesion,
        nombreCurso: nombreCurso,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        precio: precioNum,
        PorcentajePagoProfe: PorcentajePagoProfe,
        cantidadCuotasCurso:CantidadCuotasCurso
         // Asegúrate de enviar el precio como número
    };
    
    console.log(body);

    try {
        // Enviar la solicitud POST a la API
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        if (!response.ok) {
            throw new Error(`Error: ${response.statusText}`);
        }

        // Obtener la respuesta de la API
        const data = await response.json();

        // Mostrar el mensaje de éxito con SweetAlert2
        Swal.fire({
            icon: 'success',
            title: 'Curso Creado Exitosamente',
            text: data.mensaje,  // Muestra el mensaje "Curso registrado exitosamente"
        }).then(() => {
            // Recargar la página después de que el usuario cierre la alerta de éxito
            location.reload();  // Recarga la página
        });

        // Cerrar el modal después de registrar el curso
        $('#createCourseModal').modal('hide');

        // Opcional: limpiar los campos del formulario después de enviar los datos
        document.getElementById('createCourseForm').reset();

    } catch (error) {
        // Manejo de errores
        console.error('Error al registrar el curso:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Hubo un problema al registrar el curso. Inténtalo de nuevo.',
        });
    }
}

// Asignar la función submitForm al evento 'click' del botón "Crear Curso"
document.getElementById('createCourseModal').addEventListener('hidden.bs.modal', function () {
    document.getElementById('createCourseForm').reset();  // Limpiar el formulario cuando se cierra el modal
});
