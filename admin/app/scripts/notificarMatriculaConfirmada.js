// Función para enviar notificación de creación de matrícula
async function notificarCreacionMatricula(phone, studentName) {
    const whatsappRequestBody = {
        chatId: `${phone}@c.us`,
        message: `Su matricula fue exitosa ¡Bienvenido!.😄`
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
}
