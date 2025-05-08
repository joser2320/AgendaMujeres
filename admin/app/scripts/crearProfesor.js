// Función para crear el nuevo profesor
function createProfesor() {
    // Obtener los valores del formulario
    const nombreProfesor = document.getElementById("nombreProfesor").value;
    const correo = document.getElementById("correo").value;
    const telefono = document.getElementById("telefono").value;
    const cedula = document.getElementById("cedula").value;

    // Obtener el token de sesión
    const tokenSesion = sessionStorage.getItem("tokenSesion");

    // Verificar que los campos estén completos
    if (!nombreProfesor || !correo || !telefono || !cedula || !tokenSesion) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Por favor, complete todos los campos obligatorios.',
        });
        return;
    }

    // Crear objeto JSON para enviar a la API
    const profesorData = {
        nombreProfesor: nombreProfesor,
        correo: correo,
        telefono: telefono,
        cedula: cedula,
        tokenSesion: tokenSesion // Incluir el token de sesión
    };

    // Enviar solicitud HTTP POST
    fetch("http://127.0.0.1/api/crearProfesor.php", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(profesorData)
    })
    .then(response => {
        if (response.status === 201) { // Comprobar si el estado es 201
            return response.json(); // Parsear la respuesta como JSON
        } else {
            throw new Error('Error al crear el profesor, por favor revisa los datos ingresados.');
        }
    })
    .then(data => {
        // Mostrar SweetAlert de éxito
        Swal.fire({
            icon: 'success',
            title: '¡Profesor creado!',
            text: data.mensaje, // Mensaje de la API
        }).then(() => {
            // Cerrar el modal
            CloseModal('crearProfesorModal');
            // Opcionalmente, puedes recargar la página aquí
            window.location.reload();
        });
    })
    .catch(error => {
        // Mostrar SweetAlert de error en caso de error
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: error.message || 'Hubo un problema al crear el profesor. Por favor, inténtalo de nuevo.',
        });
    });
}
