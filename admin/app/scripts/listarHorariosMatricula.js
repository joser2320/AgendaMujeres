// Función para abrir el modal y llenar los horarios
async function OpencheduleListModal(cursoID, NombreCurso) {
    const url = 'http://127.0.0.1/api/listarHorariosCurso.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Usamos sessionStorage como ejemplo

    // Actualizar el nombre del curso en el título del modal
    const courseNameElement = document.getElementById('ListHorariosCourseName');
    courseNameElement.textContent = NombreCurso; // Coloca el nombre del curso en el título
    document.getElementById('HorarioCursoIdList').value = cursoID; // Asigna el ID del curso

    const body = {
        tokenSesion: tokenSesion,
        cursoID: cursoID
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

        const horarios = await response.json(); // Almacenar los horarios obtenidos

        // Llenar la tabla de horarios
        renderScheduleTable(horarios, cursoID);

        // Mostrar el modal
        $('#viewScheduleModal').modal('show');

    } catch (error) {
        console.error('Error al consultar los horarios:', error);
        // Usando SweetAlert en lugar de alert
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error al cargar los horarios. Intente nuevamente más tarde.',
            confirmButtonText: 'Aceptar'
        });
    }
}

// Función para renderizar la tabla de horarios
function renderScheduleTable(horarios, cursoID) {
    const scheduleTableBody = document.getElementById('scheduleTableBody');
    scheduleTableBody.innerHTML = ''; // Limpiar contenido anterior

    horarios.forEach((horario) => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${horario.idHorario}</td>
            <td>${horario.Dia}</td>
            <td>${horario.HoraInicio}</td>
            <td>${horario.HoraFin}</td>
            <td>${horario.Profesor}</td>
            <td>${horario.CupoInicial}</td>
            <td>${horario.CupoRestante}</td>
            <td>
                ${horario.CupoRestante <= 0 ? 
                    '<span style="color: red; font-weight: bold;">Agotado</span>' : 
                    `<span 
                        style="cursor: pointer;" 
                        onclick="abrirCrearMatriculaModal(${horario.idHorario}, ${cursoID})" 
                        title="Matricula manual"
                    >
                        <i class="fas fa-book"></i> Matricular

                    </span>`
                }
            </td>
            <td>
            <span 
                        style="cursor: pointer;" 
                        onclick="abrirEditarHorarioModal(${horario.idHorario},${horario.CupoInicial})" 
                        title="Matricula manual"
                    >
                        <i class="fas fa-edit"></i> Editar Horario

                    </span>
            </td>

        `;
        scheduleTableBody.appendChild(row);
    });
}


// Nueva función para abrir el modal de crear matrícula y pasar los parámetros
function abrirCrearMatriculaModal(idHorario, cursoID) {
    $('#viewScheduleModal').modal('hide');

    // Asignar los valores de ID al modal de crear matrícula
    document.getElementById('idCursoMatricular').value = cursoID;
    document.getElementById('idHorarioMatricular').value = idHorario;

    // Abrir el modal
    $('#crearMatriculaModal').modal('show');
}

function abrirEditarHorarioModal(idHorario, Cupo) {
    $('#viewScheduleModal').modal('hide');

    document.getElementById('HorarioId').value = idHorario;
    document.getElementById('cupoEdit').value = Cupo;

    // Cargar los profesores y luego seleccionar el actual
    cargarProfesores('professorEdit');

    $('#EditScheduleModal').modal('show');
}