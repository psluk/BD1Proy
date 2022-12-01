/*
    Funcionalidad del menú para creación de propiedades
*/

// Enlaces
const tiposApi = './get/categories/id';
const crearApi = './post/person'

// Identificadores de elementos
const formId = 'form';
const buttonId = 'createButton';
const listaTipos = 'tipoDocumento';
const nombreId = 'nameBox';
const valorDocumentoId = 'idBox';
const telefonosId = ['phoneNo1', 'phoneNo2'];
const correoElectronicoId = 'emailBox';

function esperarTipos(solicitudTipos) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudTipos.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperarTipos(solicitudTipos); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudTipos.status != 200) {
            let textoError = "Ocurrió un error (" + solicitudTipos.status + "). Inténtelo nuevamente.";
            document.getElementById(listaTipos).firstElementChild.innerHTML = textoError;
            alert(textoError);
            return;
        }

        let datos = JSON.parse(solicitudTipos.response);

        if (datos.status != undefined) {
            // El código de salida debería ser 0
            if (datos.status != 0) {
                // (Los códigos de error vienen documentados en el script del SP)
                let textoError;
                switch (datos.status) {
                    case 50000:
                        textoError = "Ocurrió un error. Inténtelo nuevamente.";
                        break;

                    case 50001:
                        textoError = "No tiene permiso para ver los tipos de zonas.";
                        break;

                    default:
                        textoError = "Ocurrió un error. Inténtelo nuevamente.";
                        break;
                }
                document.getElementById(listaTipos).firstElementChild.innerHTML = textoError;
                alert(textoError);
                return;
            }
        } else {
            // No hay código de salida, así que lo recibido no es válido
            let textoError = "Ocurrió un error. Inténtelo nuevamente.";
            document.getElementById(listaTipos).firstElementChild.innerHTML = textoError;
            alert(textoError);
        }

        let nuevaOpcion;        // Opción de la lista desplegable
        let lista = document.getElementById(listaTipos);
        lista.innerHTML = '';   // Se eliminan las opciones actuales

        for (let i = 0; i < datos.results.length; i++) {
            nuevaOpcion = lista.appendChild(document.createElement('option'));
            nuevaOpcion.value = datos.results[i].nombre;
            nuevaOpcion.innerText = datos.results[i].nombre;
        }

        lista.disabled = false;
    }
}

function obtenerTipos() {
    // Para obtener la lista de tipos de zona
    let solicitudTipos = new XMLHttpRequest();
    solicitudTipos.open('GET', tiposApi, true); // Asincrónico
    solicitudTipos.send();
    esperarTipos(solicitudTipos);
}

function esperarRespuesta(solicitudCrear) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudCrear.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperarRespuesta(solicitudCrear); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudCrear.status != 200) {
            try {
                alert("Ocurrió un error: " + JSON.parse(solicitudCrear.response).statusInfo + ".\n\nInténtelo nuevamente.");
            } catch (error) {
                alert("Ocurrió un error (" + solicitudCrear.status + ").\n\nInténtelo nuevamente.");
            }
            document.getElementById(buttonId).disabled = false;
            return;
        }

        let datos = JSON.parse(solicitudCrear.response);
        if (datos.status == 0) {
            alert("Persona creada exitosamente");
            location.reload();
        } else {
            alert("Ocurrió un error: " + datos.statusInfo + ".\n\nInténtelo nuevamente.");
        }

        document.getElementById(buttonId).disabled = false;
    }
}

window.addEventListener('load', function () {
    // Esto se ejecuta hasta después de que se cargue la página
    obtenerTipos();

    // Cambia el comportamiento por defecto de los campos de inicio de sesión
    if (document.getElementById(formId)) {
        document.getElementById(formId).onsubmit = function () {
            document.getElementById(buttonId).disabled = true;

            if (document.getElementById(listaTipos).disabled) {
                alert("Deben haberse cargado los tipos de documentos para poder continuar");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (document.getElementById(telefonosId[0]).value != parseInt(document.getElementById(telefonosId[0]).value).toString()) {
                alert("Valor de teléfono 1 no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (document.getElementById(telefonosId[1]).value != parseInt(document.getElementById(telefonosId[1]).value).toString()) {
                alert("Valor de teléfono 2 no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (!document.getElementById(correoElectronicoId).value) {
                alert("Valor de correo electrónico no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            }

            let datosPersona = {
                'id': document.getElementById(valorDocumentoId).value,
                'tipoId': document.getElementById(listaTipos).selectedOptions[0].value,
                'nombre': document.getElementById(nombreId).value,
                'telefono1': parseInt(document.getElementById(telefonosId[0]).value),
                'telefono2': parseInt(document.getElementById(telefonosId[1]).value),
                'email': document.getElementById(correoElectronicoId).value
            }

            let solicitudCrear = new XMLHttpRequest();
            solicitudCrear.open("POST", crearApi, true);
            solicitudCrear.setRequestHeader("Content-Type", "application/json;charset=utf-8");
            solicitudCrear.send(JSON.stringify(datosPersona));

            esperarRespuesta(solicitudCrear);
        };
    }
})