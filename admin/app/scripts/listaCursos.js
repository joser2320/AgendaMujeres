const cursosPorPagina = 10;  // Número de cursos por página
    let paginaActual = 1;
    let cursos = [];  // Aquí almacenaremos los cursos obtenidos desde la API

    // Función para listar cursos y llenar la tabla
    async function listarCursos() {
        const url = 'http://127.0.0.1/api/listarCursos.php';
        const tokenSesion = sessionStorage.getItem('tokenSesion');  // Usamos sessionStorage como ejemplo

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

            cursos = await response.json();  // Almacenar los cursos obtenidos

            // Filtrar y mostrar los cursos en la página actual
            const cursosFiltrados = filtrarCursos();
            const cursosPagina = cursosFiltrados.slice((paginaActual - 1) * cursosPorPagina, paginaActual * cursosPorPagina);
            renderTabla(cursosPagina);
            renderPaginacion(cursosFiltrados);

        } catch (error) {
            console.error('Error al consultar los cursos:', error);
        }
    }

    // Función para filtrar los cursos por búsqueda
    function filtrarCursos() {
        const searchTerm = document.getElementById('searchInput').value.toLowerCase();
        return cursos.filter(curso => curso.NombreCurso.toLowerCase().includes(searchTerm));
    }

    // Función para renderizar la tabla
    function renderTabla(cursosPagina) {
        const userTableBody = document.getElementById('userTableBody');
        userTableBody.innerHTML = ''; // Limpiar contenido anterior

        cursosPagina.forEach((curso) => {
            const estado = new Date(curso.FechaFin) > new Date() ? 'Activo' : 'Finalizado';

            const row = document.createElement('tr');
            row.innerHTML = `
                <td>A00${curso.cursoID}</td>
                <td>${curso.NombreCurso}</td>
                <td>${estado}</td>
                <td>
                    <i class="fas fa-image" style="cursor: pointer;" onclick="openImageModal(${curso.cursoID},'${curso.NombreCurso}')"></i>
                </td>
                <td>
                    <i class="fas fa-calendar" style="cursor: pointer;" onclick="OpencheduleListModal(${curso.cursoID},'${curso.NombreCurso}')"></i>
                </td>
                <td>₡ ${curso.Precio}</td>
                <td>
                    <button class="btn btn-secondary btn-sm" onclick="openEditCourseModal(${curso.cursoID}, '${curso.NombreCurso}', '', '${curso.FechaInicio}', '${curso.FechaFin}',${curso.Precio},${curso.PorcentajePagoProfe},${curso.pagadoProfe})">Editar</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteCurso(${curso.cursoID})">Eliminar</button>
                    <button class="btn btn-success btn-sm" onclick="OpencheduleModal(${curso.cursoID},'${curso.NombreCurso}')">Añadir Horarios</button>
                </td>
            `;
            userTableBody.appendChild(row);
        });
    }

    // Función para renderizar la paginación
    function renderPaginacion(cursosFiltrados) {
        const paginacion = document.getElementById('pagination');
        paginacion.innerHTML = ''; // Limpiar paginación

        const totalPaginas = Math.ceil(cursosFiltrados.length / cursosPorPagina);

        for (let i = 1; i <= totalPaginas; i++) {
            const botonPagina = document.createElement('li');
            botonPagina.classList.add('page-item');
            botonPagina.innerHTML = `<a class="page-link" href="#" onclick="cambiarPagina(${i})">${i}</a>`;
            paginacion.appendChild(botonPagina);
        }
    }

    // Función para cambiar de página
    function cambiarPagina(pagina) {
        paginaActual = pagina;
        const cursosFiltrados = filtrarCursos();
        const cursosPagina = cursosFiltrados.slice((paginaActual - 1) * cursosPorPagina, paginaActual * cursosPorPagina);
        renderTabla(cursosPagina);
        renderPaginacion(cursosFiltrados);
    }

    // Evento de búsqueda
    document.getElementById('searchInput').addEventListener('input', () => {
        const cursosFiltrados = filtrarCursos();
        const cursosPagina = cursosFiltrados.slice((paginaActual - 1) * cursosPorPagina, paginaActual * cursosPorPagina);
        renderTabla(cursosPagina);
        renderPaginacion(cursosFiltrados);
    });

    // Ejecutar la función cuando la página cargue
    document.addEventListener('DOMContentLoaded', listarCursos);