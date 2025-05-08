// Función para crear el nuevo usuario
function createUser() {
    // Obtener los valores del formulario
        const email = document.getElementById("CreateUserEmail").value;
        const password = document.getElementById("CreateUserPassword").value;
        const fullName = document.getElementById("CreateUserName").value;
        const status = document.getElementById("CreateUserStatus").value;
        
        // Roles
        const rolAdmin = document.getElementById("roleAdmin").checked;
        const rolServicio = document.getElementById("roleServicio").checked;
        const rolContable = document.getElementById("roleContable").checked;
        const rolReporteria = document.getElementById("roleReportería").checked;

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

        // Crear objeto JSON para enviar a la API
        const userData = {
            email: email,
            password: password,
            fullName: fullName,
            tokenSesion: tokenSesion,
            rolAdmin: rolAdmin,
            rolServicio: rolServicio,
            rolContable: rolContable,
            rolReporteria: rolReporteria
        };

        // Enviar solicitud HTTP POST
        fetch("http://127.0.0.1/api/register.php", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(userData)
        })
        .then(response => {
            if (response.status === 201) {
                // Mostrar SweetAlert de éxito
                Swal.fire({
                    icon: 'success',
                    title: '¡Usuario creado!',
                    text: 'El usuario ha sido creado correctamente.',
                }).then(() => {
                    // Opcionalmente, puedes cerrar el modal aquí si lo deseas
                    window.location.reload()

                });
            } else {
                // Mostrar SweetAlert de error si no es 201
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Hubo un problema al crear el usuario, puede que el email ya esta en uso. Por favor, inténtalo de nuevo.',
                });
            }
        })
        .catch(error => {
            // En caso de error en la solicitud
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Hubo un error al realizar la solicitud. Por favor, intenta nuevamente.',
            });
        });
    }