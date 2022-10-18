/*
    Funcionalidad del menú para creación de propiedades
*/

// Enlaces
const zonasApi = './get/categories/areas';
const usosApi = './get/categories/uses';
const crearApi = './post/property'

// Identificadores de elementos
const listaZonas = 'areaType';
const listaUsos = 'useType';
const formId = 'form';
const buttonId = 'createButton';
const finca = 'numberBox';
const area = 'areaBox';
const valor = 'valueBox';
const medidor = 'waterBox';

function esperarZonas(solicitudZonas) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudZonas.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperarZonas(solicitudZonas); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudZonas.status != 200) {
            let textoError = "Ocurrió un error (" + solicitudZonas.status + "). Inténtelo nuevamente.";
            document.getElementById(listaZonas).firstElementChild.innerHTML = textoError;
            alert(textoError);
            return;
        }

        let datos = JSON.parse(solicitudZonas.response);

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
                document.getElementById(listaZonas).firstElementChild.innerHTML = textoError;
                alert(textoError);
                return;
            }
        } else {
            // No hay código de salida, así que lo recibido no es válido
            let textoError = "Ocurrió un error. Inténtelo nuevamente.";
            document.getElementById(listaZonas).firstElementChild.innerHTML = textoError;
            alert(textoError);
        }

        let nuevaOpcion;        // Opción de la lista desplegable
        let lista = document.getElementById(listaZonas);
        lista.innerHTML = '';   // Se eliminan las opciones actuales

        for (let i = 0; i < datos.results.length; i++) {
            nuevaOpcion = lista.appendChild(document.createElement('option'));
            nuevaOpcion.value = datos.results[i].nombre;
            nuevaOpcion.innerText = datos.results[i].nombre;
        }

        lista.disabled = false;
    }
}

function esperarUsos(solicitudUsos) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudUsos.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperarUsos(solicitudUsos); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudUsos.status != 200) {
            let textoError = "Ocurrió un error (" + solicitudUsos.status + "). Inténtelo nuevamente.";
            document.getElementById(listaUsos).firstElementChild.innerHTML = textoError;
            alert(textoError);
            return;
        }

        let datos = JSON.parse(solicitudUsos.response);

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
                        textoError = "No tiene permiso para ver los tipos de usos.";
                        break;

                    default:
                        textoError = "Ocurrió un error. Inténtelo nuevamente.";
                        break;
                }
                document.getElementById(listaUsos).firstElementChild.innerHTML = textoError;
                alert(textoError);
                return;
            }
        } else {
            // No hay código de salida, así que lo recibido no es válido
            let textoError = "Ocurrió un error. Inténtelo nuevamente.";
            document.getElementById(listaUsos).firstElementChild.innerHTML = textoError;
            alert(textoError);
        }

        let nuevaOpcion;        // Opción de la lista desplegable
        let lista = document.getElementById(listaUsos);
        lista.innerHTML = '';   // Se eliminan las opciones actuales

        for (let i = 0; i < datos.results.length; i++) {
            nuevaOpcion = lista.appendChild(document.createElement('option'));
            nuevaOpcion.value = datos.results[i].nombre;
            nuevaOpcion.innerText = datos.results[i].nombre;
        }

        lista.disabled = false;
    }
}

function obtenerZonas() {
    // Para obtener la lista de tipos de zona
    let solicitudZonas = new XMLHttpRequest();
    solicitudZonas.open('GET', zonasApi, true); // Asincrónico
    solicitudZonas.send();
    esperarZonas(solicitudZonas);
}

function obtenerUsos() {
    // Para obtener la lista de tipos de usos
    let solicitudUsos = new XMLHttpRequest();
    solicitudUsos.open('GET', usosApi, true);   // Asincrónico
    solicitudUsos.send();
    esperarUsos(solicitudUsos);
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
            alert("Propiedad creada exitosamente");
            location.reload();
        } else {
            alert("Ocurrió un error: " + datos.statusInfo + ".\n\nInténtelo nuevamente.");
        }

        document.getElementById(buttonId).disabled = false;
    }
}

window.addEventListener('load', function () {
    // Esto se ejecuta hasta después de que se cargue la página
    obtenerZonas();
    obtenerUsos();

    // Cambia el comportamiento por defecto de los campos de inicio de sesión
    if (document.getElementById(formId)) {
        document.getElementById(formId).onsubmit = function () {
            document.getElementById(buttonId).disabled = true;

            if (document.getElementById(listaZonas).disabled || document.getElementById(listaUsos).disabled) {
                alert("Deben haberse cargado los tipos de uso y de zona para poder continuar");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (document.getElementById(finca).value != parseFloat(document.getElementById(finca).value).toString()) {
                alert("Valor de área no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (document.getElementById(finca).value != parseInt(document.getElementById(finca).value).toString()) {
                alert("Valor de número de finca no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (document.getElementById(medidor).value != parseInt(document.getElementById(medidor).value).toString()) {
                alert("Valor de número de medidor no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            }

            let datosPropiedad = {
                'numeroFinca': parseInt(document.getElementById(finca).value),
                'area': Math.round(parseFloat(document.getElementById(area).value)),
                'tipoZona': document.getElementById(listaZonas).selectedOptions[0].value,
                'tipoUso': document.getElementById(listaUsos).selectedOptions[0].value,
                'valorFiscal': parseInt(document.getElementById(valor).value),
                'numeroMedidor': parseInt(document.getElementById(medidor).value)
            }

            let solicitudCrear = new XMLHttpRequest();
            solicitudCrear.open("POST", crearApi, true);
            solicitudCrear.setRequestHeader("Content-Type", "application/json;charset=utf-8");
            solicitudCrear.send(JSON.stringify(datosPropiedad));

            esperarRespuesta(solicitudCrear);
        };
    }
})