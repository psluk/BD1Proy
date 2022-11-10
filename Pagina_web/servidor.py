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

# Lista de tipos de uso


@app.route("/sub/get/categories/uses")
def tipos_de_uso():
    return json.dumps(logica.listaDeUsos(
        consultante=session['username']
    ))

# Lista de tipos de zona


@app.route("/sub/get/categories/areas")
def tipos_de_zona():
    return json.dumps(logica.listaDeZonas(
        consultante=session['username']
    ))

# Creación de propiedades


@app.route("/sub/post/property", methods=['POST'])
def crear_propiedad():
    try:
        request_data = request.get_json()
    except:
        # Si falla el "parse" del JSON
        return json.dumps({"statusInfo": "Bad request"}), 400
    resultado = logica.crearPropiedad(
        informacion=request_data,
        consultante=session['username'],
        consultante_ip=request.remote_addr
    )
    
    info = ""
    codigo_estado = 200
    if resultado["status"] == 0:
        info = "OK"
    elif resultado["status"] == 500:
        info = "Error interno del servidor"
        codigo_estado = 500
    elif resultado["status"] == 50000:
        info = "Error desconocido"
        codigo_estado = 500
    elif resultado["status"] == 50001:
        info = "Error desconocido"
        codigo_estado = 500
    elif resultado["status"] == 50002:
        info = "Credenciales incorrectas"
        codigo_estado = 401
    elif resultado["status"] == 50003:
        info = "Número de finca inválido"
        codigo_estado = 400
    elif resultado["status"] == 50004:
        info = "Valor de área inválido"
    elif resultado["status"] == 50005:
        info = "No existe el tipo de zona"
    elif resultado["status"] == 50006:
        info = "No existe el tipo de uso"
    elif resultado["status"] == 50007:
        info = "Ya hay una propiedad con ese número de finca"
    elif resultado["status"] == 50008:
        info = "Número de medidor inválido"
    elif resultado["status"] == 50009:
        info = "Ya existe un medidor con ese número"
    
    resultado["statusInfo"] = info
    return json.dumps(resultado), codigo_estado

# Eliminación de propiedades


@app.route("/sub/post/property_delete", methods=['POST'])
def eliminar_propiedad():
    try:
        request_data = request.get_json()
    except:
        # Si falla el "parse" del JSON
        return json.dumps({"statusInfo": "Bad request"}), 400
    resultado = logica.eliminarPropiedad(
        informacion=request_data,
        consultante=session['username'],
        consultante_ip=request.remote_addr
    )
    
    info = ""
    codigo_estado = 200
    if resultado["status"] == 0:
        info = "OK"
    elif resultado["status"] == 500:
        info = "Error interno del servidor"
        codigo_estado = 500
    elif resultado["status"] == 50000:
        info = "Error desconocido"
        codigo_estado = 500
    elif resultado["status"] == 50001:
        info = "Error desconocido"
        codigo_estado = 500
    elif resultado["status"] == 50002:
        info = "Credenciales incorrectas"
        codigo_estado = 401
    elif resultado["status"] == 50003:
        info = "No existe una propiedad con ese número de finca"
        codigo_estado = 400
    
    resultado["statusInfo"] = info
    return json.dumps(resultado), codigo_estado

# Obtener todas las propiedades


@app.route("/sub/get/all_properties")
def todas_las_propiedades():
    return json.dumps(logica.todasLasPropiedades(
        consultante=session['username']
    ))

# Obtener todos los usuarios


@app.route("/sub/get/all_users")
def todos_los_usuarios():
    return json.dumps(logica.todosLosUsuarios(
        consultante=session['username']
    ))

# Obtener todas las personas


@app.route("/sub/get/all_people")
def todas_las_personas():
    return json.dumps(logica.todasLasPersonas(
        consultante=session['username']
    ))

# Conceptos de cobro de propiedad


@app.route("/sub/get/criteria_of_property/<finca>")
def conceptos_de_propiedad(finca: str = ''):
    return json.dumps(logica.conceptosDePropiedad(
        finca=finca,
        consultante=session['username']
    ))

# Datos de una única propiedad


@app.route("/sub/get/property/<finca>")
def leer_propiedad(finca: str = ''):
    return json.dumps(logica.leerPropiedad(
        finca=finca,
        consultante=session['username']
    ))


# Actualización de propiedades


@app.route("/sub/post/property_update", methods=['POST'])
def actualizar_propiedad():
    try:
        request_data = request.get_json()
    except:
        # Si falla el "parse" del JSON
        return json.dumps({"statusInfo": "Bad request"}), 400
    resultado = logica.actualizarPropiedad(
        informacion=request_data,
        consultante=session['username'],
        consultante_ip=request.remote_addr
    )
    
    info = ""
    codigo_estado = 200
    if resultado["status"] == 0:
        info = "OK"
    elif resultado["status"] == 500:
        info = "Error interno del servidor"
        codigo_estado = 500
    elif resultado["status"] == 50000:
        info = "Error desconocido"
        codigo_estado = 500
    elif resultado["status"] == 50001:
        info = "Error desconocido"
        codigo_estado = 500
    elif resultado["status"] == 50002:
        info = "Credenciales incorrectas"
        codigo_estado = 401
    elif resultado["status"] == 50003:
        info = "No existe una propiedad con ese número de finca"
        codigo_estado = 400
    elif resultado["status"] == 50004:
        info = "Valor de área inválido"
    elif resultado["status"] == 50005:
        info = "No existe el tipo de zona"
    elif resultado["status"] == 50006:
        info = "No existe el tipo de uso"
    
    resultado["statusInfo"] = info
    return json.dumps(resultado), codigo_estado

# Asociación de usuarios


@app.route("/sub/push/property_link", methods=['POST'])
def asociar_usuario():
    try:
        request_data = request.get_json()
    except:
        # Si falla el "parse" del JSON
        return json.dumps({"statusInfo": "Bad request"}), 400
    return json.dumps(logica.asociarUsuario(
        informacion=request_data,
        consultante=session['username'],
        consultante_ip=request.remote_addr
    ))

# Desasociación de usuarios


@app.route("/sub/push/property_unlink", methods=['POST'])
def desasociar_usuario():
    try:
        request_data = request.get_json()
    except:
        # Si falla el "parse" del JSON
        return json.dumps({"statusInfo": "Bad request"}), 400
    return json.dumps(logica.desasociarUsuario(
        informacion=request_data,
        consultante=session['username'],
        consultante_ip=request.remote_addr
    ))

# Tipo de usuario


@app.route("/sub/get/usertype")
def tipo_de_usuario():
    if logica.usuarioEsAdmin(
        consultante=session['username']
    ):
        return "1"
    else:
        return "0"

@app.route("/get/usertype")
def tipo_de_usuario2():
    if logica.usuarioEsAdmin(
        consultante=session['username']
    ):
        return "1"
    else:
        return "0"

# Facturas de una propiedad

@app.route("/sub/get/property_receipts/<finca>")
def facturas_de_propiedad(finca: str = ''):
    return json.dumps(logica.facturasDePropiedad(
        finca=finca,
        consultante=session['username']
    ))

# Detalles de una factura

@app.route("/sub/get/receipt_details/<argumentos>")
def detalles_de_factura(argumentos: str = ''):
    argumentos_separados = argumentos.split('&')
    return json.dumps(logica.detallesDeFactura(
        finca=argumentos_separados[0],
        fecha=argumentos_separados[1],
        consultante=session['username']
    ))