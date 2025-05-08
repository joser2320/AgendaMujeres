// Importar las funciones necesarias desde los SDK que necesitas
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

// Configuración de Firebase
const firebaseConfig = {
    apiKey: "AIzaSyAtvlO4mvc0K1KTrIfQiOci2IEPD_ZS-Z8",
    authDomain: "matriculasmujeres-e2535.firebaseapp.com",
    projectId: "matriculasmujeres-e2535",
    storageBucket: "matriculasmujeres-e2535.appspot.com",
    messagingSenderId: "148484258693",
    appId: "1:148484258693:web:95398ac8aca4b8aa00a2ec",
    measurementId: "G-DKT6TQJ5N2"
  };

// Inicializar Firebase
const app = initializeApp(firebaseConfig);
const storage = getStorage(app);

// Función para subir una imagen a Firebase Storage y guardar el URL en sessionStorage
export function uploadImage() {
    const fileInput = document.getElementById('imageFile');
    const file = fileInput.files[0];

    if (!file) {
        alert("Por favor selecciona una imagen.");
        return;
    }

    // Muestra el estado de carga
    document.getElementById('uploadStatus').style.display = 'block';

    // Crea una referencia a la ubicación en Firebase Storage
    const storageRef = ref(storage, 'images/' + file.name);
    
    // Sube el archivo
    const uploadTask = uploadBytes(storageRef, file);

    // Observa los cambios en el estado de la carga
    uploadTask.on(
        'state_changed',
        (snapshot) => {
            // Opcional: puedes mostrar el progreso aquí
            const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            console.log('Progreso de subida: ' + progress + '%');
        },
        (error) => {
            // Manejo de errores
            console.error('Error al subir la imagen:', error);
            alert('Error al subir la imagen. Verifica la consola para más detalles.');
            document.getElementById('uploadStatus').style.display = 'none';
        },
        () => {
            // Cuando la carga se complete, obtenemos el URL público
            uploadTask.snapshot.ref.getDownloadURL().then((downloadURL) => {
                console.log('URL de la imagen subida:', downloadURL);

                // Guardar el URL en sessionStorage
                sessionStorage.setItem('uploadedImageURL', downloadURL);

                // Mostrar el URL en la consola o hacer cualquier otra acción
                alert('Imagen subida con éxito. URL guardado en sessionStorage.');

                // Cierra el modal (si corresponde)
                // closeModal('uploadImageModal');

                // Restablece el formulario
                document.getElementById('uploadImageForm').reset();
                document.getElementById('uploadStatus').style.display = 'none';
            });
        }
    );
}
