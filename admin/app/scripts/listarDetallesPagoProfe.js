// Función para obtener el parámetro de la URL
function getUrlParameter(name) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(name);
}

// Función para cargar los detalles de pago al cargar la página
async function loadPaymentDetails() {
    const url = 'http://127.0.0.1/api/ListarPagosProfeDetalle.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Usamos sessionStorage como ejemplo
    const idCurso = getUrlParameter('IdCurso'); 
    const IdProfesor = getUrlParameter('idProfesor'); // Obtener el idCurso de la URL
    // Obtener el idCurso de la URL

    // Validar que se haya obtenido el idCurso
    if (!idCurso) {
        console.error('El parámetro IdCurso no se encontró en la URL.');
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se pudo obtener el ID del curso.',
            confirmButtonText: 'Aceptar'
        });
        return;
    }

    const body = {
        tokenSesion: tokenSesion,
        idCurso: idCurso,
        IdProfesor: IdProfesor
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        // Validar el estado de la respuesta
        if (!response.ok) {
            throw new Error(`Error: ${response.statusText}`);
        }

        const data = await response.json(); // Almacenar los datos obtenidos

        // Llenar la tabla de pagos
        renderPaymentTable(data.detalles);

        // Mostrar el monto total en el h4
        const totalMonto =  data.totalMonto || "0.00"; // Asegurar que tenga un valor predeterminado
        document.getElementById('MontoTotalPago').textContent = totalMonto;
        document.getElementById("montoPagoProfe").value = parseFloat(totalMonto);

    } catch (error) {
        console.error('Error al consultar los pagos:', error);
        // Usando SweetAlert en lugar de alert
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error al cargar los pagos. Intente nuevamente más tarde.',
            confirmButtonText: 'Aceptar'
        });
    }
}

// Función para renderizar la tabla de pagos
function renderPaymentTable(pagos) {
    const matriculaTableBody = document.getElementById('matriculaTableBody');
    matriculaTableBody.innerHTML = ''; // Limpiar contenido anterior

    pagos.forEach((pago) => {
        const row = document.createElement('tr');
        row.className = 'hover:bg-gray-100 transition duration-300'; // Color de fondo al pasar el mouse

        row.innerHTML = `
            <td class="border-b border-gray-200 text-center py-2">${pago.idPago}</td>
            <td class="border-b border-gray-200 text-center py-2">${pago.NombreCurso}</td>
            <td class="border-b border-gray-200 text-center py-2">${pago.NombreProfesor}</td>
            <td class="border-b border-gray-200 text-center py-2">${pago.CedulaProfesor}</td>
            <td class="border-b border-gray-200 text-center py-2">${pago.TelefonoProfesor}</td>
            <td class="border-b border-gray-200 text-center py-2">${pago.CorreoProfesor}</td>
            <td class="border-b border-gray-200 text-center py-2 font-semibold text-red-600">₡ ${pago.TotalPagar}</td>
        `;

        matriculaTableBody.appendChild(row);
    });
}

// Cargar los detalles de pago cuando se carga la página
document.addEventListener('DOMContentLoaded', loadPaymentDetails);
