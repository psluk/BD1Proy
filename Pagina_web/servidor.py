from flask import Flask, render_template, session, redirect, url_for, request
from markupsafe import escape
import logica  # Comunicación con el servidor de la base de datos
import json

app = Flask(__name__)

app.secret_key = "aa66460520c901b30d309bf7f2a9f9880b2a02b7ef2d177871d7c118ba1355cf"


@app.route("/")
def index():
    if 'username' not in session:
        # Si no hay un nombre de usuario en la sesión,
        # se lo redirige al inicio de sesión
        return redirect(url_for('login'))
    return render_template('index.html')


@app.route("/login", methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Se está enviando la información de inicio de sesión
        # Hay que revisar la información en la base de datos
        try:
            request_data = request.get_json()
        except:
            # Si falla el "parse" del JSON
            return "Bad request", 400

        if logica.isUsuarioValido(
                str(request_data.get('username')),
                str(request_data.get('password'))
        ):
            session['username'] = str(request_data.get('username'))
            return "Ok", 200
        else:
            return "Wrong credentials", 401
    else:
        # Si no es "POST", no se está enviando la información de inicio
        # de sesión, así que solo se revisa si ya hay una sesión o no
        if 'username' in session:
            # En este caso, ya hay una sesión, entonces no carga
            # el inicio de sesión
            return redirect(url_for('index'))
        return render_template('login.html')


@app.route("/logout")
def logout():
    # Cierra la sesión
    session.pop('username', None)
    return redirect(url_for('login'))  # Regresa al inicio de sesión


# Subpáginas

@app.route("/sub/<subpage>")
def subpagina(subpage):
    return render_template(f'subpages/{escape(subpage)}')


# Las API de las subpáginas

# Propiedades de un usuario

@app.route("/sub/get/user_properties")
def propiedades_de_usuario_actual():
    # Propiedades propias
    return json.dumps(logica.propiedadesDeUsuario(
        usuarioConsultado=session['username'],
        consultante=session['username']
    ))


@app.route("/sub/get/user_properties/<usuario>")
def propiedades_de_usuario(usuario: str = ''):
    # Propiedades de alguien más
    return json.dumps(logica.propiedadesDeUsuario(
        usuarioConsultado=usuario,
        consultante=session['username']
    ))

# Propiedades de una persona


@app.route("/sub/get/owner_properties/<identificacion>")
def propiedades_de_persona(identificacion: str = ''):
    # Propiedades de alguien más
    return json.dumps(logica.propiedadesDePersona(
        identificacion=identificacion,
        consultante=session['username']
    ))

# Lecturas de una propiedad


@app.route("/sub/get/water_history/<finca>")
def lecturas_de_propiedad(finca: str = ''):
    return json.dumps(logica.lecturasDePropiedad(
        finca=finca,
        consultante=session['username']
    ))

# Dueños de una propiedad


@app.route("/sub/get/owners_of_property/<finca>")
def propietarios_de_propiedad(finca: str = ''):
    return json.dumps(logica.propietariosDePropiedad(
        finca=finca,
        consultante=session['username']
    ))

# Usuarios asociados a una propiedad


@app.route("/sub/get/users_of_property/<finca>")
def usuarios_de_propiedad(finca: str = ''):
    return json.dumps(logica.usuariosDePropiedad(
        finca=finca,
        consultante=session['username']
    ))

# Medidores de una propiedad


@app.route("/sub/get/water_meters/<finca>")
def medidores_de_propiedad(finca: str = ''):
    return json.dumps(logica.medidoresDePropiedad(
        finca=finca,
        consultante=session['username']
    ))