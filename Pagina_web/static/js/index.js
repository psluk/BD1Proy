/* Funciones que agrega la funcionalidad de los enlaces de la parte superior */

// Identificadores
const claseFull = 'fullPage';
const claseSinParametros = 'noParameters';
const idFrame = 'contenedor';
const idDivSuperior = 'upperDiv';
const soloAdmin = 'adminOnly';

// Acciones
const categories = [
    {
        name: 'Propiedades',
        adminOnly: true,
        groups: [
            {
                name: 'Consultar',
                adminOnly: true,
                items: [
                    {
                        name: 'Lista de todas las propiedades',
                        url: './sub/see_properties.html',
                        parametersNeeded: false,
                        adminOnly: true
                    },
                    {
                        name: 'Dueños de una propiedad',
                        url: './sub/owners_of_property.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    },
                    {
                        name: 'Usuarios de una propiedad',
                        url: './sub/users_of_property.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    },
                    {
                        name: 'Conceptos de cobro de una propiedad',
                        url: './sub/criteria_of_property.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    },
                    {
                        name: 'Medidores de una propiedad',
                        url: './sub/water_meters.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    },
                    {
                        name: 'Historial de agua de una propiedad',
                        url: './sub/water_history.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    },
                    {
                        name: 'Facturas de una propiedad',
                        url: './sub/property_receipts.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    }
                ]
            },
            {
                name: 'Administrar',
                adminOnly: true,
                items: [
                    {
                        name: 'Crear propiedad',
                        url: './sub/create_property.html',
                        parametersNeeded: false,
                        adminOnly: true
                    },
                    {
                        name: 'Actualizar propiedad',
                        url: './sub/update_property.html?finca=',
                        parametersNeeded: true,
                        adminOnly: true
                    },
                    {
                        name: 'Eliminar propiedad',
                        url: './sub/delete_property.html',
                        parametersNeeded: false,
                        adminOnly: true
                    },
                    {
                        name: 'Asociar o desasociar usuario',
                        url: './sub/link_user.html',
                        parametersNeeded: false,
                        adminOnly: true
                    }
                ]
            }
        ]
    },
    {
        name: 'Personas',
        adminOnly: true,
        groups: [
            {
                name: 'Consultar',
                adminOnly: true,
                items: [
                    {
                        name: 'Lista de todas las personas',
                        url: './sub/see_people.html',
                        parametersNeeded: false,
                        adminOnly: true
                    },
                    {
                        name: 'Propiedades de una persona',
                        url: './sub/owner_properties.html?id=',
                        parametersNeeded: true,
                        adminOnly: true
                    }
                ]
            },
            {
                name: 'Administrar',
                adminOnly: true,
                items: []
            }
        ]
    },
    {
        name: 'Usuarios',
        adminOnly: true,
        groups: [
            {
                name: 'Consultar',
                adminOnly: true,
                items: [
                    {
                        name: 'Lista de todos los usuarios',
                        url: './sub/see_users.html',
                        parametersNeeded: false,
                        adminOnly: true
                    },
                    {
                        name: 'Propiedades de un usuario',
                        url: './sub/user_properties.html?user=',
                        parametersNeeded: true,
                        adminOnly: true
                    }
                ]
            },
            {
                name: 'Administrar',
                adminOnly: true,
                items: [
                    {
                        name: 'Asociar o desasociar propiedad',
                        url: './sub/link_user.html',
                        parametersNeeded: false,
                        adminOnly: true
                    }
                ]
            }
        ]
    },
    {
        name: 'Otros',
        adminOnly: true,
        groups: [
            {
                name: 'Consultar',
                adminOnly: true,
                items: [
                    {
                        name: 'Lista de todos los pagos',
                        url: './sub/see_payments.html',
                        parametersNeeded: false,
                        adminOnly: true
                    },
                    {
                        name: 'Lista de eventos',
                        url: './sub/see_events.html',
                        parametersNeeded: false,
                        adminOnly: true
                    }
                ]
            }
        ]
    }
];

window.addEventListener('load', function () {
    // Esto se ejecuta hasta que se haya terminado de cargar la página

    // Cambia el comportamiento por defecto de los enlaces de la parte superior
    let divSuperior = document.getElementById(idDivSuperior);
    let nuevaLista;
    let nuevoElemento;
    let nuevoGrupo;
    let grupo;

    for (let i = 0; i < categories.length; i++) {
        nuevaLista = divSuperior.insertBefore(document.createElement('select'), divSuperior.lastElementChild);

        nuevoElemento = nuevaLista.appendChild(document.createElement('option'));
        nuevoElemento.innerText = categories[i].name;
        nuevoElemento.value = '0';
        
        if (categories[i].adminOnly) {
            nuevaLista.setAttribute('class', soloAdmin);
            nuevoElemento.setAttribute('class', soloAdmin);
        }

        for (let j = 0; j < categories[i].groups.length; j++) {
            grupo = categories[i].groups[j];
            nuevoGrupo = nuevaLista.appendChild(document.createElement('optgroup'));
            nuevoGrupo.label = grupo.name;

            if (grupo.adminOnly) {
                nuevoGrupo.setAttribute('class', soloAdmin);
            }

            for (let k = 0; k < grupo.items.length; k++) {
                nuevoElemento = nuevoGrupo.appendChild(document.createElement('option'));
                nuevoElemento.innerText = grupo.items[k].name;
                nuevoElemento.value = i + '.' + j + '.' + k;

                if (categories[i].adminOnly) {
                    nuevoElemento.setAttribute('class', soloAdmin);
                }
            }
        }

        nuevaLista.addEventListener('change', cargarOpcion)
    }
})

function cargarOpcion(evento) {
    /* Función que carga la opción deseada */

    if (!evento.target.value || evento.target.value == "0") {
        return;
    }

    let actionId = evento.target.value.split(".");
    actionId[0] = parseInt(actionId[0]);
    actionId[1] = parseInt(actionId[1]);
    actionId[2] = parseInt(actionId[2]);

    let action = categories[actionId[0]].groups[actionId[1]].items[actionId[2]];
    let enlace = action.url;

    if (action.parametersNeeded)
    {
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
    else {
        document.getElementById(idFrame).src = enlace;
    }

    evento.target.selectedIndex = 0; // Vuelve a seleccionar la primera opción
}