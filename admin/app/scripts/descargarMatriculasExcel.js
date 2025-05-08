async function descargarMatriculasExcel() {
    const url = 'http://127.0.0.1/api/listarMatriculas_Reporte.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Recupera el token de sessionStorage

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

        const matriculas = await response.json(); // Los datos de los movimientos

        // Crear una nueva hoja de trabajo
        const ws = XLSX.utils.json_to_sheet(matriculas);

        // Crear un nuevo libro de trabajo
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Matriculas');

        // Generar un archivo Excel y desencadenar la descarga
        XLSX.writeFile(wb, 'Matriculas.xlsx');

    } catch (error) {
        console.error('Error al descargar las matriculas:', error);
        // Mostrar un SweetAlert en caso de error
        Swal.fire({
            title: 'Error',
            text: 'No hay matriculas para mostrar.',
            icon: 'error',
            confirmButtonText: 'Aceptar'
        });
    }
}

// Puedes agregar un botón en tu HTML para desencadenar esta función
document.getElementById('descargarExcelMatriculasBtn').addEventListener('click', descargarMatriculasExcel);
