let currentPage = 1; 
const itemsPerPage = 6;
let originalCourses = []; // Almacenamos la lista original de cursos
let filteredCourses = [];

// Función para formatear la fecha en dd-mm-aaaa
function formatDate(dateString) {
    const dateParts = dateString.split('-'); // Divide la fecha en partes
    return `${dateParts[2]}-${dateParts[1]}-${dateParts[0]}`; // Reorganiza a dd-mm-aaaa
}

// Función para cargar los cursos desde la API
async function loadCourses() {
    try {
        const response = await fetch('http://127.0.0.1/api/ListaCursosUsuarioFinal.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            throw new Error('Error al cargar los cursos');
        }

        const coursesFromApi = await response.json();
        // Mapeamos los datos de la API al formato necesario
        originalCourses = coursesFromApi.map(course => ({
            id: course.IdCurso,
            title: course.NombreCurso,
            price: parseFloat(course.Precio.replace(/,/g, '')), // Convertir a número eliminando la coma
            formattedPrice: `₡${parseFloat(course.Precio.replace(/,/g, '')).toFixed(2)}`, // Precio formateado con 2 decimales
            image: course.ImagenCurso || 'assets/images/course/cursoImagenDefault.jpg', // Usa una imagen por defecto si no hay
            description: course.Descripcion,
            startDate: formatDate(course.FechaInicio), // Formateamos la fecha de inicio
            endDate: formatDate(course.FechaFin), // Formateamos la fecha de fin
            students: parseInt(course.cupo_total - course.cantidad_matriculas),
            cuotas: parseInt(course.cantidadCuotas),

        }));

        filteredCourses = [...originalCourses]; // Inicializa la lista filtrada con la lista original
        displayCourses();
    } catch (error) {
        console.error('Error:', error);
    }
}

// Función para mostrar cursos
function displayCourses() {
    const start = (currentPage - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    const currentCourses = filteredCourses.slice(start, end);

    const courseList = document.getElementById('course-list');
    courseList.innerHTML = '';

    // Mostrar mensaje si no hay cursos coincidentes
    if (filteredCourses.length === 0) {
        courseList.innerHTML = '<p>No se encontraron cursos que coincidan con la búsqueda.</p>';
        return;
    }

    currentCourses.forEach(course => {
        
        const precioFinal = course.price / course.cuotas;

        
        const courseHTML = `
            <div class="col-lg-4 col-md-6">
                <div class="course-block">
                    <div class="course-img">
                        <img src="${course.image}" alt="${course.title}" onclick="showDetails(${course.id})" class="img-fluid">
                    </div>
                    <div class="course-content">
                        <div class="course-price">₡${precioFinal}/Mes</div> <!-- Usar el precio formateado -->
                        <h5>${course.cuotas} meses</h5>
                        <h4><a href="#" onclick="showDetails(${course.id})">${course.title}</a></h4>
                        <p>Fecha de inicio: <strong>${course.startDate}</strong></p>
                        <p>Fecha de fin: <strong>${course.endDate}</strong></p>
                        <div class="course-footer d-lg-flex align-items-center justify-content-between">
                            <div class="course-meta">
                                <span class="course-student"><a>Quedan: </a>${course.students} espacios</span>
                            </div>
                            <div class="buy-btn">
                                ${(new Date(course.endDate.split('-').reverse().join('-')) < new Date()) 
                                    ? '<span class="text-danger">Curso Finalizado</span>' 
                                    : (new Date(course.startDate.split('-').reverse().join('-')) <= new Date()) 
                                        ? '<span class="text-danger">Curso Iniciado</span>' 
                                        : (course.students === 0 
                                            ? '<span class="text-danger">Agotado</span>' 
                                            : `<a href="#" class="btn btn-main-2 btn-small" onclick="openMatriculaModal(${course.id})">Matricular</a>`)}
                            </div>


                        </div>
                        <div class="details-link">
                            <a href="#" onclick="showDetails(${course.id})">Ver detalles</a>
                        </div>
                    </div>
                </div>
            </div>
        `;
        courseList.innerHTML += courseHTML;
    });

    updateResultsCount();
    generatePagination();
}

// Función para mostrar detalles del curso usando SweetAlert
function showDetails(courseId) {
    const course = filteredCourses.find(c => c.id === courseId);
    if (course) {
        Swal.fire({
            title: course.title,
            html: `
                <p><strong>Descripción:</strong> ${course.description}</p>
                <p><strong>Fecha de inicio:</strong> ${course.startDate}</p>
                <p><strong>Fecha de fin:</strong> ${course.endDate}</p>
                <p><strong>Cupos restantes:</strong> ${course.students}</p>
            `,
            imageUrl: course.image,
            imageWidth: '200px', // Ajusta el ancho de la imagen
            imageHeight: 'auto', // Mantiene la altura automática para la proporción
            imageAlt: course.title,
            confirmButtonText: 'Cerrar',
            customClass: {
                popup: 'custom-popup' // Clase personalizada para el popup
            }
        });
    }
}

// Estilo CSS para el popup
const style = document.createElement('style');
style.innerHTML = `
    .custom-popup {
        max-width: 90%; 
        width: auto; 
        height: auto; 
    }
    
    .course-img {
        width: 100%; /* Asegúrate de que el contenedor tenga el ancho deseado */
        height: 200px; /* Mantén una altura fija */
        overflow: hidden; /* Oculta cualquier desbordamiento */
    }

    .course-img img {
        width: 100%;
        height: auto; /* Mantiene la proporción de la imagen */
        object-fit: cover; /* O usar contain según lo que necesites */
    }
`;
document.head.appendChild(style);

// Función para generar la paginación
function generatePagination() {
    const totalPages = Math.ceil(filteredCourses.length / itemsPerPage);
    const pagination = document.getElementById('pagination');
    pagination.innerHTML = '';

    for (let i = 1; i <= totalPages; i++) {
        const activeClass = i === currentPage ? 'active' : '';
        pagination.innerHTML += `
            <li class="page-num ${activeClass}">
                <a href="#" onclick="changePage(${i}, event)">${i}</a>
            </li>
        `;
    }
}

// Función para cambiar de página
function changePage(page, event) {
    if (event) {
        event.preventDefault();
    }
    currentPage = page;
    displayCourses();
}

// Función para actualizar el conteo de resultados
function updateResultsCount() {
    const resultsCount = document.getElementById('results-count');
    resultsCount.textContent = `Mostrando ${Math.min((currentPage - 1) * itemsPerPage + 1, filteredCourses.length)}-${Math.min(currentPage * itemsPerPage, filteredCourses.length)} de ${filteredCourses.length} resultados`;
}

// Función para manejar la búsqueda
document.getElementById('search-input').addEventListener('input', function(e) {
    const searchTerm = e.target.value.toLowerCase();
    if (searchTerm) {
        // Filtra los cursos si hay texto en el campo de búsqueda
        filteredCourses = originalCourses.filter(course => course.title.toLowerCase().includes(searchTerm));
    } else {
        // Si el campo de búsqueda está vacío, restablece la lista filtrada a la original
        filteredCourses = [...originalCourses];
    }
    currentPage = 1;  // Reinicia a la primera página
    displayCourses(); // Muestra los cursos filtrados en la primera página
});

// Inicializa la carga de cursos
loadCourses();
