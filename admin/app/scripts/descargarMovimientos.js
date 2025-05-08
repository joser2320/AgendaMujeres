async function descargarMovimientosExcel() {
    const url = 'http://127.0.0.1/api/GetDataReportMoney.php'; // API que devuelve los movimientos
    const tokenSesion = sessionStorage.getItem('tokenSesion'); // Obtener el token de sesión

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

        const movimientos = await response.json(); // Los datos de los movimientos

        // Crear una nueva hoja de trabajo
        const ws = XLSX.utils.json_to_sheet(movimientos);

        // Crear un nuevo libro de trabajo
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Movimientos');

        // Generar un archivo Excel y desencadenar la descarga
        XLSX.writeFile(wb, 'Movimientos de Dinero.xlsx');

    } catch (error) {
        console.error('Error al descargar los movimientos:', error);
        // Mostrar un SweetAlert en caso de error
        Swal.fire({
            title: 'Error',
            text: 'No hay movimmientos de dinero para mostrar.',
            icon: 'error',
            confirmButtonText: 'Aceptar'
        });
    }
}

// Puedes agregar un botón en tu HTML para desencadenar esta función
document.getElementById('descargarExcelBtn').addEventListener('click', descargarMovimientosExcel);
