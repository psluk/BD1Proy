
const enlaceApi = "./get/usertype"
const claseOcultar = "adminOnly"

function esperar(solicitudTipo) {
    // Función que espera hasta que el servidor retorna la información
    if (solicitudTipo.readyState < 4) {
        // 4 = listo
        setTimeout(function () { esperar(solicitudTipo); }, 100)
        // 100 = revisa cada 100 milisegundos
    } else {
        if (solicitudTipo.response == "1") {
            let estilo = document.head.appendChild(document.createElement('style'));
            estilo.innerHTML = "." + claseOcultar + " { display: initial; }";
        }
    }
}


window.addEventListener('load', function () {
    // Esto se ejecuta hasta después de que se cargue la página

    let solicitudTipo = new XMLHttpRequest();
    solicitudTipo.open("GET", enlaceApi, true);
    solicitudTipo.send();
    esperar(solicitudTipo);
});