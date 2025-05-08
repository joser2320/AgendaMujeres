const matriculasPorPagina = 30; // Número de matrículas por página
let paginaActual = 1;
let matriculas = []; // Aquí almacenaremos las matrículas obtenidas desde la API
let matriculasFiltradas = []; // Aquí almacenaremos las matrículas filtradas

// Función para listar matrículas y llenar la tabla al cargar
async function listarMatriculas() {
    const url = 'http://127.0.0.1/api/listarMatriculas.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Recupera el token de sessionStorage

    const body = {
        tokenSesion: tokenSesion // Usa el token recuperado
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

        matriculas = await response.json(); // Almacenar todas las matrículas obtenidas
        matriculasFiltradas = matriculas; // Inicialmente, las filtradas son todas

        // Mostrar todos los registros en la primera carga
        mostrarPagina(paginaActual);

    } catch (error) {
        console.error('Error al consultar las matrículas:', error);
    }
}

// Función para filtrar por columna específica
function filtrarColumna(columna, valorBusqueda) {
    const valorBusquedaLower = valorBusqueda.toLowerCase();

    // Si el campo de búsqueda está vacío, muestra todas las matrículas
    if (valorBusquedaLower === '') {
        matriculasFiltradas = matriculas; // Mostrar todos los registros
    } else {
        // Filtrar las matrículas que coincidan en la columna indicada
        matriculasFiltradas = matriculas.filter(matricula => {
            const valorColumna = obtenerValorColumna(matricula, columna).toLowerCase();
            return valorColumna.includes(valorBusquedaLower); // Filtrar por inclusión
        });
    }

    // Mostrar la primera página de los datos filtrados
    mostrarPagina(1);
}

// Función para obtener el valor de la columna basado en el índice
function obtenerValorColumna(matricula, columna) {
    switch (columna) {
        case 0: return matricula.Id ? matricula.Id.toString() : '';
        case 1: return matricula.NombreCurso || '';
        case 2: return matricula.Horario || '';
        case 3: return matricula.NombreCompleto || '';
        case 4: return matricula.Cedula || '';
        case 5: return matricula.Telefono || '';
        case 6: return matricula.Correo || '';
        case 7: return matricula.estadoPago || '';
        case 8: return matricula.CuotasPendientes ? matricula.CuotasPendientes.toString() : '';
        case 9: return matricula.MesesPendientes ? matricula.MesesPendientes.toString() : '';
        case 10: return matricula.MontoCuota ? matricula.MontoCuota.toString() : '';
        case 11: return matricula.MontoAdeudado ? matricula.MontoAdeudado.toString() : '';
        case 12: return matricula.formaPago || '';
        default: return '';
    }
}

// Función para mostrar los datos de la tabla paginados
function mostrarPagina(pagina) {
    paginaActual = pagina;
    const inicio = (pagina - 1) * matriculasPorPagina;
    const fin = inicio + matriculasPorPagina;
    const datosPagina = matriculasFiltradas.slice(inicio, fin); // Usar las matriculas filtradas
    renderTabla(datosPagina);
    renderPaginacion(matriculasFiltradas); // Usar las matriculas filtradas para paginación
}

// Función para renderizar la tabla
function renderTabla(datosPagina) {
    const matriculaTableBody = document.getElementById('matriculaTableBody');
    matriculaTableBody.innerHTML = ''; // Limpiar contenido anterior

    datosPagina.forEach((matricula) => {
        const row = document.createElement('tr');

        // Aplicar estilo condicional al estado de pago
        const estadoPagoStyle = matricula.estadoPago === 'Pendiente'
            ? 'style="color: red; font-weight: bold;"'
            : 'style="color: green; font-weight: bold;"';

        row.innerHTML = `<td class="text-center"># ${matricula.Id}</td>
<td class="text-center">${matricula.NombreCurso || 'N/A'}</td>
<td class="text-center">${matricula.Horario || 'N/A'}</td>
<td class="text-center">${matricula.NombreCompleto || 'N/A'}</td>
<td class="text-center">${matricula.Cedula}</td>
<td class="text-center">${matricula.Telefono}</td>
<td class="text-center">${matricula.Correo}</td>
<td class="text-center" ${estadoPagoStyle}>${matricula.estadoPago}</td>
<td class="text-center">${matricula.CuotasPendientes}</td>
<td class="text-center">${matricula.MesesPendientes.toUpperCase()}</td>
<td class="text-center">₡${matricula.MontoCuota}</td>
<td class="text-center">₡${matricula.MontoAdeudado}</td>
<td class="text-center">${matricula.comprobante}</td>
<td class="text-center">${matricula.formaPago}</td>
<td class="text-center">
    ${matricula.estadoPago === 'Pendiente' ? 
        `<button class="btn btn-success btn-sm mr-1" onclick="opencambiarEstadoMatriculaModal(${matricula.Id}, '${matricula.comprobante}', ${matricula.MontoCuota},${matricula.CuotasPendientes},'${matricula.Telefono}')">Incluir Pago</button>` 
        : ''}
    <button class="btn btn-danger btn-sm mr-1" onclick="deleteMatricula(${matricula.Id})">Cancelar</button>
    <button class="btn btn-info btn-sm" onclick="abrirModalUpdateMetodoPago(${matricula.Id})">Método de pago</button>
</td>

        `;

        matriculaTableBody.appendChild(row);
    });
}

// Función para renderizar la paginación
function renderPaginacion(matriculasFiltradas) {
    const pagination = document.getElementById('pagination');
    pagination.innerHTML = ''; // Limpiar contenido anterior

    const totalPaginas = Math.ceil(matriculasFiltradas.length / matriculasPorPagina);

    for (let i = 1; i <= totalPaginas; i++) {
        const li = document.createElement('li');
        li.className = 'page-item';
        li.innerHTML = `<a class="page-link" href="#" onclick="mostrarPagina(${i})">${i}</a>`;
        pagination.appendChild(li);
    }
}

// Llamar a listarMatriculas al cargar la página
listarMatriculas();
