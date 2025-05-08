function saveUserChanges() {
    // Obtener los valores del formulario
    const email = document.getElementById("editUserEmail").value;
    const password = document.getElementById("editUserPassword").value;
    const fullName = document.getElementById("editUserName").value;
    const status = document.getElementById("editUserStatus").value;
    
    // Roles
    const rolAdmin = document.getElementById("role_Administrador").checked;
    const rolServicio = document.getElementById("role_Servicio al cliente").checked;
    const rolContable = document.getElementById("role_Contable").checked;
    const rolReporteria = document.getElementById("role_Reporteria").checked;

    // Obtener el token de sesión
    const tokenSesion = sessionStorage.getItem("tokenSesion");

    // Verificar que los campos estén completos
    if (!email || !fullName || !status) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Por favor, complete todos los campos obligatorios.',
        });
        return;
    }

    // Obtener el ID del usuario
    const usuarioID = document.getElementById("editIdUser").value;

    // Crear objeto JSON para enviar a la API
    const userData = {
        usuarioID: usuarioID,
        email: email,
        password: password,
        fullName: fullName,
        tokenSesion: tokenSesion,
        rolAdmin: rolAdmin,
        rolServicio: rolServicio,
        rolContable: rolContable,
        rolReporteria: rolReporteria,
        activo: (status === "Activo" ? 1 : 0) // Asignar 1 si el estado es "Activo", 0 si no lo es
    };

    // Enviar solicitud HTTP POST
    fetch("http://127.0.0.1/api/updateUser.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(userData)
    })
    .then(response => {
        if (response.status === 200) {
            return Swal.fire({
                icon: 'success',
                title: '¡Cambios guardados!',
                text: 'Los cambios del usuario han sido guardados correctamente.',
            }).then(() => {
                // Cerrar el modal y recargar la página si es necesario
                $('#editUserModal').modal('hide');
                window.location.reload();
            });
        } else {
            throw new Error('Error al actualizar el usuario, es probable que el correo ya esté en uso o falta completar algún campo');
        }
    })
    .catch(error => {
        // Mostrar SweetAlert de error
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: error.message || 'Hubo un error al realizar la solicitud. Por favor, intenta nuevamente.',
        });
    });
}
