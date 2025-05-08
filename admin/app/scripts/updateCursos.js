// Función para enviar los datos del formulario y actualizar el curso
async function submitEditCursoForm() {
    const url = 'http://127.0.0.1/api/UpdateCursos.php';  // URL de la API para actualizar el curso

    // Obtener los datos del formulario
    const cursoID = document.getElementById('editCourseId').value; // ID del curso a actualizar
    const nombreCurso = document.getElementById('editNombreCurso').value;
    const descripcion = document.getElementById('editDescripcion').value;
    const fechaInicio = document.getElementById('editFechaInicio').value;
    const fechaFin = document.getElementById('editFechaFin').value;
    const Precio = document.getElementById('editprecioModal').value;
    const PorcentajePagoProfe = document.getElementById('editPorcentajeProfe').value;


    // Obtener el token de sesión de sessionStorage
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    // Validar que los campos del formulario no estén vacíos
    if (!cursoID || !nombreCurso || !descripcion || !fechaInicio || !fechaFin || !tokenSesion|| !Precio ||!PorcentajePagoProfe ) {
        Swal.fire({
            icon: 'error',
            title: 'Campos Incompletos',
            text: 'Por favor, complete todos los campos.',
        });
        return;  // Detener la ejecución si algún campo está vacío
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
        tokenSesion: tokenSesion,
        cursoID: cursoID,
        NombreCurso: nombreCurso,
        Descripcion: descripcion,
        FechaInicio: fechaInicio,
        FechaFin: fechaFin,
        Precio: Precio,
        ProcentajeProfesor: PorcentajePagoProfe,
    };

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

        // Verificar si la respuesta tiene un mensaje de éxito
        const mensaje = data.mensaje || "Curso actualizado exitosamente"; // Usar un valor predeterminado si no existe "mensaje"

        // Mostrar el mensaje de éxito con SweetAlert2
        Swal.fire({
            icon: 'success',
            title: mensaje,
        }).then(() => {
            // Recargar la página después de que el usuario cierre la alerta de éxito
            location.reload();  // Recarga la página
        });

        // Cerrar el modal después de actualizar el curso
        $('#editCourseModal').modal('hide');  // Asegurarse de que este es el ID correcto

        // Opcional: limpiar los campos del formulario después de enviar los datos
        document.getElementById('editCourseForm').reset();

    } catch (error) {
        // Manejo de errores
        console.error('Error al actualizar el curso:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Hubo un problema al actualizar el curso. Inténtalo de nuevo.',
        });
    }
}

// Asignar la función submitForm al evento 'click' del botón "Actualizar Curso"
document.getElementById('editCourseModal').addEventListener('hidden.bs.modal', function () {
    document.getElementById('editCourseForm').reset();  // Limpiar el formulario cuando se cierra el modal
});
