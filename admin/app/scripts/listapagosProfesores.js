const registrosPorPagina = 5; // Número de registros a mostrar por página
let registros; // Variable para almacenar los registros de la API
let paginaActual = 1; // Página actual

async function cargarPagosPendientes() {
    const url = 'http://127.0.0.1/api/PagosPendientesProfesores.php'; // API que devuelve los pagos pendientes
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Obtener el token de sesión

    const body = {
        token: tokenSesion
    };

    try {
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

        registros = await response.json(); // Los datos de pagos pendientes
        renderizarTabla(registros); // Llenar la tabla con los registros

    } catch (error) {
        console.error('Error al cargar los pagos pendientes:', error);
    }
}

// Función para renderizar la tabla
function renderizarTabla(data) {
    const tableBody = document.getElementById('pagosPendientesTableBody');
    
    // Limpiar la tabla antes de llenarla
    tableBody.innerHTML = '';

    // Filtrar los datos según la búsqueda por cédula
    const busquedaInput = document.getElementById('searchInput').value.toLowerCase();
    const datosFiltrados = data.filter(item => item.CedulaProfesor.toLowerCase().includes(busquedaInput));

    // Calcular el total de páginas
    const totalPaginas = Math.ceil(datosFiltrados.length / registrosPorPagina);
    const datosPaginaActual = datosFiltrados.slice((paginaActual - 1) * registrosPorPagina, paginaActual * registrosPorPagina);

    // Llenar la tabla con los registros filtrados y paginados
    datosPaginaActual.forEach(pago => {
        const row = document.createElement('tr');
        
        // Crear las celdas de la fila
        row.innerHTML = `
            <td class="text-center">${pago.NombreCurso}</td>
            <td class="text-center">${pago.NombreProfesor}</td>
            <td class="text-center">${pago.CedulaProfesor}</td>
            <td class="text-center">${pago.TelefonoProfesor}</td>
            <td class="text-center">${pago.CorreoProfesor}</td>
            <td class="text-center">${parseFloat(pago.TotalPagar).toLocaleString('es-CR', { style: 'currency', currency: 'CRC' })}</td>
            <td class="text-center">
                <button class="btn btn-warning btn-sm" onclick="window.location.href='detallesCurso.html?IdCurso=${pago.idCurso}&idProfesor=${pago.idProfesor}&IdPago=${pago.idPago}'">Revisar</button>
            </td>
        `;

        // Agregar la fila al cuerpo de la tabla
        tableBody.appendChild(row);
    });

    // Renderizar paginación
    renderizarPaginacion(totalPaginas);
}

// Función para renderizar la paginación
function renderizarPaginacion(totalPaginas) {
    const pagination = document.getElementById('pagination');
    pagination.innerHTML = '';

    for (let i = 1; i <= totalPaginas; i++) {
        const pageItem = document.createElement('li');
        pageItem.className = 'page-item';
        pageItem.innerHTML = `<a class="page-link" href="#" onclick="cambiarPagina(${i})">${i}</a>`;
        pagination.appendChild(pageItem);
    }
}

// Función para cambiar de página
function cambiarPagina(pagina) {
    paginaActual = pagina;
    renderizarTabla(registros); // Renderizar nuevamente la tabla con la nueva página
}

// Función de búsqueda
function filterTable() {
    renderizarTabla(registros); // Renderizar la tabla al filtrar
}

// Función que consulta el API y muestra las alertas de SweetAlert
async function pagarCursoProfesor(cursoID) {
    try {
        const tokenSesion = sessionStorage.getItem('tokenSesion'); // Obtener el token de sesión

        // Confirmación con SweetAlert antes de proceder con el pago
        const confirmResult = await Swal.fire({
            title: '¿Estás seguro?',
            text: `Estás a punto de realizar el pago del curso con ID ${cursoID}. ¿Deseas continuar?`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sí, pagar',
            cancelButtonText: 'Cancelar'
        });

        // Si el usuario confirma, proceder con la solicitud
        if (confirmResult.isConfirmed) {
            // Crear el objeto con los datos para enviar al API
            const data = {
                tokenSesion: tokenSesion,
                cursoID: cursoID
            };

            // Hacer la solicitud POST al API
            const response = await fetch('http://127.0.0.1/api/pagarCursoIdProfe.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            // Convertir la respuesta a JSON
            const result = await response.json();

            // Verificar si la respuesta fue exitosa y mostrar alertas de SweetAlert
            if (response.ok) {
                // Mostrar la alerta de éxito
                Swal.fire({
                    icon: 'success',
                    title: 'Éxito',
                    text: result.mensaje + `\nPagos actualizados: ${result.actualizados}`
                }).then(() => {
                    // Recargar la página después de que el usuario cierre la alerta
                    location.reload();
                });
            } else {
                // Si el servidor devuelve un código de error
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: result.mensaje || 'Hubo un problema al actualizar los pagos'
                });
            }
        } else {
            // Si el usuario cancela, mostrar una alerta de cancelación
            Swal.fire({
                icon: 'info',
                title: 'Cancelado',
                text: 'El proceso de pago fue cancelado'
            });
        }
    } catch (error) {
        // Manejar errores de la solicitud (fallo de red, etc.)
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se pudo conectar con el servidor. Inténtalo más tarde.'
        });
    }
}

async function actualizarPagosPorCedula() {
    try {
        const tokenSesion = sessionStorage.getItem('tokenSesion'); // Obtener el token de sesión
        const cedula = document.getElementById('PagarCedula').value; // Obtener el token de sesión

        // Confirmación con SweetAlert antes de proceder
        const confirmResult = await Swal.fire({
            title: '¿Estás seguro?',
            text: `Estás a punto de actualizar los pagos para la cédula ${cedula}. ¿Deseas continuar?`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sí, continuar',
            cancelButtonText: 'Cancelar'
        });

        // Si el usuario confirma, proceder con la solicitud
        if (confirmResult.isConfirmed) {
            // Crear el objeto con los datos para enviar al API
            const data = {
                tokenSesion: tokenSesion,
                cedula: cedula
            };

            // Hacer la solicitud POST al API
            const response = await fetch('http://127.0.0.1/api/pagosProfesoresCedula.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            // Convertir la respuesta a JSON
            const result = await response.json();

            // Verificar si la respuesta fue exitosa y mostrar alertas de SweetAlert
            if (response.ok) {
                // Mostrar la alerta de éxito
                Swal.fire({
                    icon: 'success',
                    title: 'Éxito',
                    text: result.mensaje
                }).then(() => {
                    // Aquí puedes agregar lógica adicional, como recargar datos
                    location.reload();
                });
            } else {
                // Si el servidor devuelve un código de error
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: result.mensaje || 'Hubo un problema al actualizar los pagos'
                });
            }
        } else {
            // Si el usuario cancela, mostrar una alerta de cancelación
            Swal.fire({
                icon: 'info',
                title: 'Cancelado',
                text: 'El proceso fue cancelado'
            });
        }
    } catch (error) {
        // Manejar errores de la solicitud (fallo de red, etc.)
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se pudo conectar con el servidor. Inténtalo más tarde.'
        });
    }
}

// Ejecutar la función al cargar la página
document.addEventListener('DOMContentLoaded', cargarPagosPendientes);
