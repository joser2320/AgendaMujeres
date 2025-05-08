// Función para obtener los indicadores y actualizar la interfaz
async function obtenerIndicadores() {
    const url = 'http://127.0.0.1/api/indicadoresConta.php';
    const tokenSesion = sessionStorage.getItem('tokenSesion');  // Asumiendo que el token está en sessionStorage
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

        const indicadores = await response.json();  // Obtener los indicadores desde la API

        // Actualizar los valores en la interfaz
        document.getElementById('cantidad-cursos-activos').innerText = indicadores.cantidad_cursos_activos;
        document.getElementById('cantidad-matriculas').innerText = indicadores.cantidad_matriculas;
        document.getElementById('matriculas-pendientes-cobro').innerText = indicadores.matriculas_pendientes_cobro;
        document.getElementById('ingresos-pendientes-cobro').innerText = `₡ ${indicadores.ingresos_pendientes_cobro}`;
        document.getElementById('ingresos-confirmados').innerText = `₡ ${indicadores.ingresos_confirmados}`;
        document.getElementById('pago_a_profesor').innerText = `₡ ${indicadores.pago_a_profesor}`;
        document.getElementById('deserciones').innerText = `${indicadores.cantidad_desercion}`;


    } catch (error) {
        console.error('Error al consultar los indicadores:', error);
    }
}

// Ejecutar la función cuando la página cargue
document.addEventListener('DOMContentLoaded', obtenerIndicadores);
