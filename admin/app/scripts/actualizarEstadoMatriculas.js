function actualizarEstadoMatricula() {
    // Obtener los valores del formulario
    const idMatricula = document.getElementById("idMatricula").value;
    const CuotaPagar = document.getElementById("CuotaPagar").value;
    const notas = document.getElementById("notas").value; // Obtener notas
    const comprobante = document.getElementById("comprobanteEstado").value; // Obtener comprobante
    const telefono = document.getElementById("telefono").value; // Obtener teléfono
    // Obtener el token de sesión
    const tokenSesion = sessionStorage.getItem("tokenSesion");

    // Verificar que los campos estén completos
    if (!idMatricula || !CuotaPagar || !tokenSesion) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Por favor, complete todos los campos obligatorios.',
        });
        return;
    }

    // Crear objeto JSON para el movimiento
    const movimientoData = {
        idMatricula: idMatricula,
        cuotaPagar: CuotaPagar, // Usar el valor ingresado
        notas: notas, // Tomar notas del campo
        comprobante: comprobante, // Tomar comprobante del campo
        tokenSesion: tokenSesion // Incluir el token de sesión
    };

    // Enviar solicitud HTTP POST a la API para registrar el movimiento
    fetch("http://127.0.0.1/api/InsertarMovimientoIngreso.php", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(movimientoData)
    })
    .then(response => response.json())
    .then(data => {
        Swal.fire({
            icon: 'success',
            title: '¡Movimiento registrado correctamente!'
        }).then(() => {
            // Validar el estado de cuotas de la matrícula
            return fetch("http://127.0.0.1/api/validaPagosParaMensaje.php", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ idMatricula, tokenSesion })
            });
        })
        .then(response => response.json())
        .then(validacion => {
            let mensajeWhatsApp = validacion.Resultado === 1 
                ? "Hemos recibido su solicitud de matrícula, pronto le informaremos por este medio cuando su pago fue confirmado 🎉"
                : "Hemos recibido el pago de la cuota. ¡Muchas Gracias! 😊";
            
            // Enviar mensaje por WhatsApp
            return fetch('https://waapi.app/api/v1/instances/48511/client/action/send-message', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Authorization': `Bearer VqYXAVDiAFKAP1kRZmhonMLo3zdxmWObSS2upAm27fef1168`
                },
                body: JSON.stringify({ chatId: `${telefono}@c.us`, message: mensajeWhatsApp })
            });
        })
        .then(whatsappResponse => {
            if (whatsappResponse.ok) {
                console.log("Mensaje de WhatsApp enviado exitosamente.");

                // Si el mensaje de WhatsApp fue enviado correctamente, registrar en la nueva API
                const movimientoRegistroData = {
                    Envia: 'Sistema', // Puedes personalizar estos valores
                    Recibe: telefono,
                    Mensaje: mensajeWhatsApp,
                    FechaHora: new Date().toISOString() // Fecha y hora en formato ISO
                };

                return fetch("http://127.0.0.1/api/RegistrarLogWhatsApp.php", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(movimientoRegistroData)
                });
            } else {
                throw new Error("Error al enviar el mensaje de WhatsApp.");
            }
        })
        .then(registroResponse => {
            if (registroResponse.ok) {
                console.log("Movimiento registrado en la API exitosamente.");
                CloseModal('cambiarEstadoMatriculaModal');
                window.location.reload();
            } else {
                throw new Error("Error al registrar el movimiento en la API.");
            }
        })
        .catch(error => {
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: error.message
            });
        });
    })
    .catch(error => {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Hubo un problema al registrar el movimiento. Por favor, inténtalo de nuevo.',
        });
    });
}
