/*
    Funcionalidad del menú para la eliminación de propiedades
*/

// Enlaces
const borrarApi = './post/property_delete'

// Identificadores de elementos
const formId = 'form';
const buttonId = 'createButton';
const finca = 'numberBox';

// Parámetros dentro del URL
const parametrosUrl = new URLSearchParams(window.location.search);
const propiedadBuscada = parametrosUrl.get('finca');

function esperarRespuesta(solicitudEliminar) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudEliminar.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperarRespuesta(solicitudEliminar); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudEliminar.status != 200) {
            try {
                alert("Ocurrió un error: " + JSON.parse(solicitudEliminar.response).statusInfo + ".\n\nInténtelo nuevamente.");
            } catch (error) {
                alert("Ocurrió un error (" + solicitudEliminar.status + ").\n\nInténtelo nuevamente.");
            }
            document.getElementById(buttonId).disabled = false;
            return;
        }

        let datos = JSON.parse(solicitudEliminar.response);
        if (datos.status == 0) {
            alert("Propiedad eliminada exitosamente");
        } else {
            alert("Ocurrió un error: " + datos.statusInfo + ".\n\nInténtelo nuevamente.");
        }

        document.getElementById(buttonId).disabled = false;
    }
}

window.addEventListener('load', function () {
    // Cambia el comportamiento por defecto de los campos de inicio de sesión
    if (document.getElementById(formId)) {
        document.getElementById(formId).onsubmit = function () {
            document.getElementById(buttonId).disabled = true;

            let datosPropiedad = {
                'numeroFinca': parseInt(document.getElementById(finca).value),
            }

            if (!confirm("¿Está seguro de querer borrar la propiedad con número de finca " + parseInt(document.getElementById(finca).value) + "?")) {
                document.getElementById(buttonId).disabled = false;
                return;
            }

            let solicitudEliminar = new XMLHttpRequest();
            solicitudEliminar.open("POST", borrarApi, true);
            solicitudEliminar.setRequestHeader("Content-Type", "application/json;charset=utf-8");
            solicitudEliminar.send(JSON.stringify(datosPropiedad));

            esperarRespuesta(solicitudEliminar);
        };
    }

    if (propiedadBuscada) {
        document.getElementById(finca).value = propiedadBuscada;
        setTimeout(function () { document.getElementById(buttonId).click() }, 50);
    }
})