

async function cargarProfesores() {
    const url = 'http://127.0.0.1/api/listarProfesores.php'; // API que devuelve los profesores
    const tokenSesion = sessionStorage.getItem('tokenSesion');  // Obtener el token de sesión

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

        const profesores = await response.json();  // Los datos de los profesores
        const tableBody = document.getElementById('ProfesorTableBody');
        
        // Limpiar la tabla antes de llenarla
        tableBody.innerHTML = '';

        // Llenar la tabla con los profesores obtenidos
        profesores.forEach(profesor => {
            const row = document.createElement('tr');
            
            // Crear las celdas de la fila
            row.innerHTML = `
                <td># ${profesor.profesorID}</td>
                <td>${profesor.NombreProfesor}</td>
                <td>${profesor.Correo}</td>
                <td>${profesor.Telefono}</td>
                <td>${profesor.Cedula}</td>
                
               
            `;
            if (sessionStorage.getItem('Administrador') == 1) {
                row.innerHTML += `
                <td>
                    <button  class="btn btn-danger btn-sm" onclick="deleteProfesor(${profesor.profesorID})">Eliminar</button>
                </td>
                `;
            }

            // Agregar la fila al cuerpo de la tabla
            tableBody.appendChild(row);
        });

    } catch (error) {
        console.error('Error al cargar los profesores:', error);
    }
}

// Ejecutar la función al cargar la página
document.addEventListener('DOMContentLoaded', cargarProfesores);
