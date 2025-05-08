const MovimientosPorPagina = 30;
let paginaActual = 1;
let Movimientos = [];
let MovimientosFiltradas = [];

async function listarMovimientos() {
    const url = 'http://127.0.0.1/api/GetDataReportMoney.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    const body = {
        tokenSesion: tokenSesion
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

        Movimientos = await response.json();
        MovimientosFiltradas = Movimientos;
        mostrarPagina(paginaActual);

    } catch (error) {
        console.error('Error al consultar los movimientos:', error);
    }
}

function filtrarColumna(columna, valorBusqueda) {
    const valorBusquedaLower = valorBusqueda.toLowerCase();

    if (valorBusquedaLower === '') {
        MovimientosFiltradas = Movimientos;
    } else {
        MovimientosFiltradas = Movimientos.filter(Movimiento => {
            const valorColumna = obtenerValorColumna(Movimiento, columna).toLowerCase();
            return valorColumna.includes(valorBusquedaLower);
        });
    }

    mostrarPagina(1);
}

function obtenerValorColumna(Movimiento, columna) {
    switch (columna) {
        case 0: return Movimiento.CONSECUTIVO ? Movimiento.CONSECUTIVO.toString() : '';
        case 1: return Movimiento.TIPO_MOVIMIENTO || '';
        case 2: return Movimiento.MONTO || '';
        case 3: return Movimiento.NOMBRE_CURSO || '';
        case 4: return Movimiento.ID_MATRICULA ? Movimiento.ID_MATRICULA.toString() : '';
        case 5: return Movimiento.ENVIA || '';
        case 6: return Movimiento.RECIBE || '';
        case 7: return Movimiento.CEDULA_CLIENTE_PAGA || '';
        case 8: return Movimiento.NOMBRE_CLIENTE_PAGA || '';
        case 9: return Movimiento.TELEFONO_CLIENTE_PAGA || '';
        case 10: return Movimiento.EMAIL_CLIENTE_PAGA || '';
        case 11: return Movimiento.NOTAS || '';
        case 12: return Movimiento.COMPROBANTE || '';
        case 13: return Movimiento.FECHA || '';
        default: return '';
    }
}

function mostrarPagina(pagina) {
    paginaActual = pagina;
    const inicio = (pagina - 1) * MovimientosPorPagina;
    const fin = inicio + MovimientosPorPagina;
    const datosPagina = MovimientosFiltradas.slice(inicio, fin);
    renderTabla(datosPagina);
    renderPaginacion(MovimientosFiltradas);
}

function renderTabla(datosPagina) {
    const MovimientoTableBody = document.getElementById('MovimientosTableBody');
    MovimientoTableBody.innerHTML = '';

    datosPagina.forEach((Movimiento) => {
        const row = document.createElement('tr');

        row.innerHTML = `
            <td class="text-center"># ${Movimiento.CONSECUTIVO}</td>
            <td class="text-center">${Movimiento.TIPO_MOVIMIENTO || 'N/A'}</td>
            <td class="text-center">₡${Movimiento.MONTO}</td>
            <td class="text-center">${Movimiento.NOMBRE_CURSO || 'N/A'}</td>
            <td class="text-center">${Movimiento.ID_MATRICULA}</td>
            <td class="text-center">${Movimiento.ENVIA} ➜ ${Movimiento.RECIBE}</td>
            <td class="text-center">${Movimiento.CEDULA_CLIENTE_PAGA}</td>
            <td class="text-center">${Movimiento.NOMBRE_CLIENTE_PAGA}</td>
            <td class="text-center">${Movimiento.TELEFONO_CLIENTE_PAGA}</td>
            <td class="text-center">${Movimiento.EMAIL_CLIENTE_PAGA}</td>
            <td class="text-center">${Movimiento.NOTAS || '-'}</td>
            <td class="text-center">${Movimiento.COMPROBANTE}</td>
            <td class="text-center">${Movimiento.FECHA}</td>
            <td class="text-center">
                <button class="btn btn-warning btn-sm" onclick="revertirPago(${Movimiento.CONSECUTIVO},${Movimiento.ID_MATRICULA})">Revertir</button>
            </td>

        `;

        MovimientoTableBody.appendChild(row);
    });
}

function renderPaginacion(MovimientosFiltradas) {
    const pagination = document.getElementById('pagination');
    pagination.innerHTML = '';

    const totalPaginas = Math.ceil(MovimientosFiltradas.length / MovimientosPorPagina);

    for (let i = 1; i <= totalPaginas; i++) {
        const li = document.createElement('li');
        li.className = 'page-item';
        li.innerHTML = `<a class="page-link" href="#" onclick="mostrarPagina(${i})">${i}</a>`;
        pagination.appendChild(li);
    }
}

// Ejecutar al cargar
listarMovimientos();

function revertirPago(idMovimiento, idMatricula) {
    const tokenSesion = sessionStorage.getItem('tokenSesion');
    const UsuarioRevierte = sessionStorage.getItem('fullName');

    // Verificar si hay token
    if (!tokenSesion) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se encontró un token de sesión válido.',
        });
        return;
    }

    // Confirmación de eliminación
    Swal.fire({
        title: '¿Estás seguro?',
        text: "Esta acción revertirá el movimiento y actualizará la matrícula.",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sí, revertir',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            const requestData = {
                tokenSesion: tokenSesion,
                idMovimiento: idMovimiento,
                idMatricula: idMatricula,

            };

            fetch('http://127.0.0.1/api/revertirPago.php', {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.codigo === 0) {
                    Swal.fire({
                        icon: 'success',
                        title: '¡Eliminado!',
                        text: data.mensaje,
                    }).then(() => {
                        location.reload();
                    });
                } else {
                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Intente nuevamente.',
                    });
                }
            })
            .catch(() => {
                Swal.fire({
                    icon: 'error',
                    title: 'Error',
                    text: 'Ocurrió un error al contactar el servidor.',
                });
            });
        }
    });
}
