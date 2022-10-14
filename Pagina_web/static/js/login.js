const formId = 'loginForm';
const userBoxId = 'usernameBox';
const passBoxId = 'passwordBox';
const buttonId = 'loginButton';

let loginButtonText = '';

function waitForResponse(loginRequest) {
    // Esto permite revisar si el servidor ya mandó la respuesta
    // (porque estamos haciendo un request asincrónico)
    // Si hiciéramos uno sincrónico, se congelaría la página
    // hasta recibir la respuesta

    if (loginRequest.readyState < 4) {
        // 4 = listo
        setTimeout(function () { waitForResponse(loginRequest); }, 100); // Revisa cada 100 ms
    }
    else {
        if (loginRequest.status == 200) {
            // Se inició la sesión exitosamente
            location.reload();
        } else if (loginRequest.status == 401) {
            // Credenciales erróneas
            alert("¡Credenciales incorrectas!\n\nInténtelo nuevamente");
            document.getElementById(buttonId).disabled = false;
        } else {
            // Un error diferente
            alert("Ocurrió un error desconocido: " + loginRequest.status + " (" + loginRequest.statusText + ")");
            document.getElementById(buttonId).disabled = false;
        }
        document.getElementById(buttonId).value = loginButtonText;
    }
}

window.addEventListener('load', function () {
    // Esto se ejecuta hasta que se haya terminado de cargar la página

    // Cambia el comportamiento por defecto de los campos de inicio de sesión
    if (document.getElementById(formId)) {
        document.getElementById(formId).onsubmit = function () {
            loginButtonText = document.getElementById(buttonId).value;
            document.getElementById(buttonId).value = "...";
            document.getElementById(buttonId).disabled = true;

            let loginData = {
                'username': document.getElementById(userBoxId).value,
                'password': document.getElementById(passBoxId).value
            }

            let loginRequest = new XMLHttpRequest();
            loginRequest.open("POST", document.URL, true);
            loginRequest.setRequestHeader("Content-Type", "application/json;charset=utf-8");
            loginRequest.send(JSON.stringify(loginData));

            waitForResponse(loginRequest);
        };
    }
})