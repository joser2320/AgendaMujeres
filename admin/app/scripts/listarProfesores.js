async function cargarProfesores(selectId = 'professorCreate') {
    const url = 'http://127.0.0.1/api/listarProfesores.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion');

    const body = { tokenSesion };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        if (!response.ok) throw new Error(`Error: ${response.statusText}`);

        const profesores = await response.json();

        const professorSelect = document.getElementById(selectId);
        professorSelect.innerHTML = '<option value="">Seleccionar Profesor</option>';

        profesores.forEach(profesor => {
            const option = document.createElement('option');
            option.value = profesor.profesorID;
            option.textContent = profesor.NombreProfesor;
            professorSelect.appendChild(option);
        });

    } catch (error) {
        console.error('Error al cargar los profesores:', error);
    }
}
