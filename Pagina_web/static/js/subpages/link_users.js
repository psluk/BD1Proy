/*
    Funcionalidad del menú para asociación y desasociación de usuarios
*/


// Enlaces
const asociarApi = './push/property_link';
const desasociarApi = './push/property_unlink'

// Identificadores de elementos
const listaOperaciones = 'operationList';
const finca = 'numberBox';
const usuario = 'userBox';
const formId = 'form';
const buttonId = 'updateButton';

function esperarRespuesta(solicitudOperacion) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudOperacion.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperarRespuesta(solicitudOperacion); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudOperacion.status != 200) {
            alert("Ocurrió un error.\n\nInténtelo nuevamente.");
            document.getElementById(buttonId).disabled = false;
            return;
        }

        let datos = JSON.parse(solicitudOperacion.response);
        if (datos.status == 0) {
            alert("Éxito");
            location.reload();
        } else {
            switch (datos.status) {
                case 50002:
                    alert("Acceso denegado.");
                    break;
            
                case 50004:
                    alert("No existe la propiedad.\n\nInténtelo nuevamente.");
                    break;
                
                case 50009:
                    alert("No existe el usuario.\n\nInténtelo nuevamente.");
                    break;

                case 50011:
                    alert("No existe la relación.\n\nInténtelo nuevamente.");
                    break;
                
                case 50012:
                    alert("Ya existe la relación.")
                    break;
            
                default:
                    alert("Ocurrió un error.\n\nInténtelo nuevamente.");
                    break;
            }
        }

        document.getElementById(buttonId).disabled = false;
    }
}

window.addEventListener('load', function () {
    // Esto se ejecuta hasta después de que se cargue la página

    // Cambia el comportamiento por defecto de los campos del formulario
    if (document.getElementById(formId)) {
        document.getElementById(formId).onsubmit = function () {
            document.getElementById(buttonId).disabled = true;

            if (!document.getElementById(finca).value || (document.getElementById(finca).value != parseInt(document.getElementById(finca).value).toString())) {
                alert("Valor de número de finca no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            } else if (!document.getElementById(usuario).value) {
                alert("Valor de nombre de usuario no válido");
                document.getElementById(buttonId).disabled = false;
                return;
            }

            let datosPropiedad = {
                'numeroFinca': parseInt(document.getElementById(finca).value),
                'usuario': document.getElementById(usuario).value
            }

            let solicitudOperacion = new XMLHttpRequest();
            if (document.getElementById(listaOperaciones).value == 1) {
                // Asociar
                solicitudOperacion.open("POST", asociarApi, true);
            } else {
                // Desasociar
                solicitudOperacion.open("POST", desasociarApi, true);
            }
            solicitudOperacion.setRequestHeader("Content-Type", "application/json;charset=utf-8");
            solicitudOperacion.send(JSON.stringify(datosPropiedad));

            esperarRespuesta(solicitudOperacion);
        };
    }
})