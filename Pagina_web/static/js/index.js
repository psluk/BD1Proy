/* Funciones que agrega la funcionalidad de los enlaces de la parte superior */

// Identificadores
const claseFull = 'fullPage';
const claseSinParametros = 'noParameters';
const idFrame = 'contenedor';
const idDivSuperior = 'upperDiv';

function recargarTodaLaPagina(elemento) {
    // Función que recarga toda la página
    window.location = elemento.href;
}

function recargarSinParametros(elemento) {
    // Función que carga una página en el contenedor sin pedir parámetros
    document.getElementById(idFrame).src = elemento.href;
}

function recargar(elemento) {
    // Función que carga una página en el contenedor pidiendo parámetros
    let enlace = elemento.href;
    let respuesta = prompt("Por favor, digite el valor de " + enlace.split('?', 2).at(-1).split('=', 1)[0] + " por consultar");
    if (respuesta != null) {
        if (!respuesta) {
            alert("Debe digitar algún valor");
        }
        else {
            document.getElementById(idFrame).src = enlace + respuesta;
        }
    }
}

window.addEventListener('load', function () {
    // Esto se ejecuta hasta que se haya terminado de cargar la página

    // Cambia el comportamiento por defecto de los enlaces de la parte superior
    let elementos;
    let divSuperior = document.getElementById(idDivSuperior);

    elementos = divSuperior.getElementsByTagName('a');
    for (let i = 0; i < elementos.length; i++) {
        if (elementos[i].classList.contains(claseFull)) {
            elementos[i].onclick = function () { recargarTodaLaPagina(this); return false; };
        } else if (elementos[i].classList.contains(claseSinParametros)) {
            elementos[i].onclick = function () { recargarSinParametros(this); return false; };
        } else {
            elementos[i].onclick = function () { recargar(this); return false; };
        }
    }
})