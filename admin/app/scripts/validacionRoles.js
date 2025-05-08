 //verifica los roles del usuario
 var IsAdmin = sessionStorage.getItem('Administrador');
 var IsServicioAlCliente = sessionStorage.getItem('ServicioAlCliente');
 var IsContable = sessionStorage.getItem('Contable');
 var IsReportaria = sessionStorage.getItem('Reportaria');

 if (IsAdmin == 0) {
      document.getElementById('AdminUsuariosMenu').style.display = 'none';
   
 }

 if (IsServicioAlCliente == 0) {
     document.getElementById('AdminUsuariosMenu').style.display = 'none';
     document.getElementById('contabilidadMenu').style.display = 'none';
     document.getElementById('matriculasMenu').style.display = 'none';
     document.getElementById('profesoresMenu').style.display = 'none';
     document.getElementById('cursosMenu').style.display = 'none';

   //  document.getElementById('EliminarProfeButton').style.display = 'none';

 }else{
   //  document.getElementById('crearProfesorButton').style.display = 'none';
 }
 
 if (IsContable == 0) {
    // document.getElementById('AdminUsuariosMenu').style.display = 'none';
    // document.getElementById('contabilidadMenu').style.display = 'none';
    // document.getElementById('matriculasMenu').style.display = 'none';
    // document.getElementById('profesoresMenu').style.display = 'none';
    // document.getElementById('cursosMenu').style.display = 'none';
   //  document.getElementById('EliminarProfeButton').style.display = 'none';

 }
 if (IsReportaria == 0) {
    // document.getElementById('AdminUsuariosMenu').style.display = 'none';
    // document.getElementById('contabilidadMenu').style.display = 'none';
    // document.getElementById('matriculasMenu').style.display = 'none';
    // document.getElementById('profesoresMenu').style.display = 'none';
    // document.getElementById('cursosMenu').style.display = 'none';
 }