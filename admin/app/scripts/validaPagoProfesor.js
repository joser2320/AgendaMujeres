async function validarPagoProfesor() {
    const apiUrl = "http://127.0.0.1/api/validaPagoProfesor.php";
    const idCurso = getUrlParameter('IdCurso');
    const data = {
        idCurso: idCurso
    };

    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            // La respuesta es 200 OK
            const responseData = await response.json();
            console.log("Validación exitosa:", responseData);
            // Puedes manejar la respuesta aquí si es necesario
        } else {
            // Manejo de errores
            const errorData = await response.json();
            mostrarAlerta(errorData.mensaje);
        }
    } catch (error) {
        console.error("Error en la solicitud:", error);
        mostrarAlerta("Ocurrió un error al realizar la solicitud.");
    }
}

function mostrarAlerta(mensaje) {
    Swal.fire({
        title: 'Error',
        text: mensaje,
        icon: 'error',
        confirmButtonText: 'Aceptar'
    }).then(() => {
        // Redirigir a la página de contabilidad
        window.location.href = "contabilidad.html"; // Ajusta la URL según sea necesario
    });
}

// Llama a la función al cargar la página o en el evento que desees
validarPagoProfesor();