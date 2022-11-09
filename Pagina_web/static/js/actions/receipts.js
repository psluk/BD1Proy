/* Programa que añade la lista de facturas de cada propiedad */

const listClass = 'actionList';
const defaultText = 'Acción...';
const actions = { /* Las acciones con "%admin%" solo las ven administradores */
    'Consultar': {
        'Detalles': './receipt_details.html?finca=fecha=',
        'Comprobante': './payment_details?ref='
    }
};
const categorias = Object.keys(actions);
const soloAdmin = "adminOnly";

const tituloId = 'moduleTitle';

let acciones = [];
for (let i = 0; i < categorias.length; i++) {
    acciones.push(Object.keys(actions[categorias[i]]));
}

function agregarAcciones() {
    /* Función que agrega la lista de facturas de cada propiedad */
    let elementosPorCambiar = document.getElementsByClassName(listClass);

    let listaActual;
    let categoriaActual;
    let opcionActual;

    for (let i = 0; i < elementosPorCambiar.length; i++) {
        listaActual = elementosPorCambiar[i];
        opcionActual = listaActual.appendChild(document.createElement('option'));
        opcionActual.innerText = defaultText;
        opcionActual.value = '0';

        for (let j = 0; j < categorias.length; j++) {
            categoriaActual = listaActual.appendChild(document.createElement('optgroup'));
            if (categorias[j].indexOf('%admin%') > -1) {
                categoriaActual.label = categorias[j].replace('%admin%', '');
                categoriaActual.setAttribute('class', soloAdmin);
            } else {
                categoriaActual.label = categorias[j];
            }

            for (let k = 0; k < acciones[j].length; k++) {
                opcionActual = categoriaActual.appendChild(document.createElement('option'));
                if (acciones[j][k].indexOf('%admin%') > -1) {
                    opcionActual.innerText = acciones[j][k].replace('%admin%', '');
                    opcionActual.setAttribute('class', soloAdmin);
                } else {
                    opcionActual.innerText = acciones[j][k];
                }
                opcionActual.value = j + "." + k;
            }
        }
        addEventListener('change', redirigir)
    }


}

function redirigir(evento) {
    /* Función que redirige a la página deseada */

    if (!evento.target.value || evento.target.value == "0") {
        return;
    }

    let action = evento.target.value.split(".");
    action[0] = parseInt(action[0]);
    action[1] = parseInt(action[1]);

    let link = actions[categorias[action[0]]][acciones[action[0]][action[1]]];
    link = link.replace('finca=', 'finca=' + document.getElementById(tituloId).innerText.split(" ").at(-1));
    link = link.replace('fecha=', 'fecha=' + evento.target.parentElement.parentElement.children[1].lastChild.innerText);
    link = link.replace('ref=', 'ref=' + evento.target.parentElement.parentElement.children[6].innerText);

    if (!evento.target.parentElement.parentElement.children[6].innerText && link.indexOf('ref=' > -1)) {
        alert('No hay pagos asociados a esta factura');
        return;
    }

    window.location = link;
}