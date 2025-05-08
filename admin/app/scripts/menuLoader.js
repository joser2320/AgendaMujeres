// menuLoader.js
document.addEventListener("DOMContentLoaded", function () {
    const menuContainer = document.getElementById("menuContainer"); // Contenedor en el HTML de cada página

    // HTML del menú que deseas cargar
    const menuHTML = `
        <div class="menu-content h-100" data-simplebar>
            <ul class="metismenu left-sidenav-menu">
                <li class="menu-label mt-0">Menú</li>
                <li id="homeMenu">
                    <a href="home.html"> 
                        <i data-feather="home" class="align-self-center menu-icon"></i>
                        <span>Reportes</span>
                    </a>                    
                </li>
                <li id="AdminUsuariosMenu">
                    <a href="usuariosAdmin.html"> 
                        <i data-feather="user" class="align-self-center menu-icon"></i>
                        <span>Administración de usuarios</span>
                    </a>                    
                </li>
                <li id="contabilidadMenu">
                    <a href="contabilidad.html"> 
                        <i data-feather="layers" class="align-self-center menu-icon"></i>
                        <span>Contabilidad</span>
                    </a>                    
                </li>
                <li id="matriculasMenu">
                    <a href="matriculas.html"> 
                        <i data-feather="book" class="align-self-center menu-icon"></i>
                        <span>Matriculas</span>
                    </a>                    
                </li>
                <li id="profesoresMenu">
                    <a href="profesores.html"> 
                        <i data-feather="user" class="align-self-center menu-icon"></i>
                        <span>Profesores</span>
                    </a>                    
                </li>
                <li id="cursosMenu">
                    <a href="cursos.html"> 
                        <i data-feather="book" class="align-self-center menu-icon"></i>
                        <span>Cursos</span>
                    </a>                    
                </li>
            </ul>
        </div>`;

    // Inyectar el HTML del menú en el contenedor
    if (menuContainer) {
        menuContainer.innerHTML = menuHTML;
    } else {
        console.error("No se encontró el contenedor de menú con el ID 'menuContainer'.");
    }

    // Opcional: Si usas Feather Icons, puedes recargar los íconos aquí
    if (typeof feather !== "undefined") {
        feather.replace();
    }
});
