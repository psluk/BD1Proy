import pyodbc as odbc

DRIVER_NAME = 'SQL SERVER'
SERVER_NAME = 'Bisquit12'
SERVER_PORT = '1433'
DATABASE_NAME = 'proyecto'
USER_UID = '1234'
USER_PWD = '1234'

CONNECTION_STRING = f"""
    DRIVER={DRIVER_NAME};
    SERVER={SERVER_NAME};
    DATABASE={DATABASE_NAME};
    PORT={SERVER_PORT};
    UID={USER_UID};
    PWD={USER_PWD};
    Trust_Connection=yes;"""

try:
    # Aquí se intenta conectar al servidor en la computadora de Luis
    conn = odbc.connect(CONNECTION_STRING)
    conn.close()
except:
    # Si llega acá, es porque no pudo
    # Utiliza los valores de la computadora de Paúl
    SERVER_NAME = 'DESKTOP-IFDQO1N'
    DATABASE_NAME = 'Proyecto'
    CONNECTION_STRING = f"""
        DRIVER={DRIVER_NAME};
        SERVER={SERVER_NAME};
        DATABASE={DATABASE_NAME};
        Trust_Connection=yes;"""

    # Trata de conectarse de nuevo
    conn = odbc.connect(CONNECTION_STRING)
    conn.close()

# Funciones


def isUsuarioValido(nombreUsuario: str = '',  clave: str = ''):
    """
    Función que verifica si un usuario y una contraseña son válidos
    Retorna True o False
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[ValidarUsuario] ?,?"

    salida = cursor.execute(query, nombreUsuario, clave)

    resultado = False

    try:
        if salida.fetchone()[0] == 1:
            resultado = True
    except:
        # No retornó nada
        resultado = False

    cursor.close()
    return resultado


# Consultar propiedades

def propiedadesDeUsuario(usuarioConsultado: str = '', consultante: str = ''):
    """
    Función que retorna las propiedades que le pertenecen a un usuario dado
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPropiedadesDeUsuario] ?,?"

    salida = cursor.execute(query, usuarioConsultado, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "numeroFinca": fila[0],
                    "uso": fila[1],
                    "zona": fila[2],
                    "area": fila[3],
                    "valorFiscal": fila[4],
                    "registro": fila[5],
                    "inicioRelacion": fila[6]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado


def propiedadesDePersona(identificacion: str = '', consultante: str = ''):
    """
    Función que retorna las propiedades que le pertenecen a una persona dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPropiedadesDePersona] ?,?"

    salida = cursor.execute(query, identificacion, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "numeroFinca": fila[0],
                    "uso": fila[1],
                    "zona": fila[2],
                    "area": fila[3],
                    "valorFiscal": fila[4],
                    "registro": fila[5],
                    "inicioRelacion": fila[6]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado


def lecturasDePropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna el historial de agua de una propiedad dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerLecturasDePropiedad] ?,?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "fecha": fila[0],
                    "tipo": fila[1],
                    "consumo": str(fila[2]),
                    "acumulado": str(fila[3])
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def propietariosDePropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna las personas a quienes pertenece una propiedad dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPropietariosDePropiedad] ?,?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombre": fila[0],
                    "id": fila[1],
                    "inicioRelacion": fila[2]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def usuariosDePropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna los usuarios a quienes está asociada una propiedad dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerUsuariosDePropiedad] ?,?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombreUsuario": fila[0],
                    "inicioRelacion": fila[1]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def medidoresDePropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna los medidores asociados a una propiedad dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerMedidoresDePropiedad] ?,?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "numeroMedidor": fila[0],
                    "acumulado": str(fila[1])
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def listaDeZonas(consultante: str = ''):
    """
    Función que retorna los diferentes tipos de zonas que existen
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[ObtenerZonas] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombre": fila[0]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def listaDeUsos(consultante: str = ''):
    """
    Función que retorna los diferentes tipos de usos que existen
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[ObtenerUsos] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombre": fila[0]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def crearPropiedad(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta crear una propiedad
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[CrearPropiedad] ?, ?, ?, ?, ?, ?, ?, ?"

    datos = []
    for i in ['tipoUso', 'tipoZona', 'numeroFinca', 'area', 'valorFiscal', 'numeroMedidor']:
        datos.append(str(informacion[i]))

    salida = cursor.execute(
        query,
        datos[0],
        datos[1],
        datos[2],
        datos[3],
        datos[4],
        datos[5],
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0
    }

    try:
        # Copia el código de salida del procedimiento
        # a lo que se retorna
        resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
        }

    cursor.commit()
    cursor.close()

    return resultado

def eliminarPropiedad(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta eliminar una propiedad
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[EliminarPropiedad] ?, ?, ?"

    datos = []
    for i in ['numeroFinca']:
        datos.append(str(informacion[i]))

    salida = cursor.execute(
        query,
        datos[0],
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0
    }

    try:
        # Copia el código de salida del procedimiento
        # a lo que se retorna
        resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
        }

    cursor.commit()
    cursor.close()

    return resultado

def todasLasPropiedades(consultante: str = ''):
    """
    Función que retorna la lista completa de propiedades
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPropiedades] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "numeroFinca": fila[0],
                    "uso": fila[1],
                    "zona": fila[2],
                    "area": fila[3],
                    "valorFiscal": fila[4],
                    "registro": fila[5]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def todosLosUsuarios(consultante: str = ''):
    """
    Función que retorna la lista completa de usuarios
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerUsuarios] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombreUsuario": fila[0],
                    "tipo": fila[1],
                    "nombrePersona": fila[2],
                    "idPersona": fila[3]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def todasLasPersonas(consultante: str = ''):
    """
    Función que retorna la lista completa de personas
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPersonas] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombre": fila[0],
                    "id": fila[1],
                    "tipoId": fila[2],
                    "telefonos": [
                        fila[3],
                        fila[4]
                        ],
                    "email": fila[5]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def conceptosDePropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna la lista de conceptos de cobro de una propiedad
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerConceptoCobroDePropiedad] ?, ?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombre": fila[0],
                    "inicioRelacion": fila[1]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def leerPropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna información de una propiedad
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerUnaPropiedad] ?, ?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "numeroFinca": fila[0],
                    "uso": fila[1],
                    "zona": fila[2],
                    "area": fila[3],
                    "valorFiscal": fila[4],
                    "registro": fila[5],
                    "numeroMedidor": fila[6]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def actualizarPropiedad(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta crear una propiedad
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[ActualizarPropiedad] ?, ?, ?, ?, ?, ?, ?"

    datos = []
    for i in ['tipoUso', 'tipoZona', 'numeroFinca', 'area', 'valorFiscal']:
        datos.append(str(informacion[i]))

    salida = cursor.execute(
        query,
        datos[0],
        datos[1],
        datos[2],
        datos[3],
        datos[4],
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0
    }

    try:
        # Copia el código de salida del procedimiento
        # a lo que se retorna
        resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
        }

    cursor.commit()
    cursor.close()

    return resultado

def asociarUsuario(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta agregar una asociación
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[AsociarUsuarioPropiedad] ?, ?, ?, ?"

    datos = []
    for i in ['usuario', 'numeroFinca']:
        datos.append(str(informacion[i]))

    salida = cursor.execute(
        query,
        datos[0],
        datos[1],
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0
    }

    try:
        # Copia el código de salida del procedimiento
        # a lo que se retorna
        resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
        }

    cursor.commit()
    cursor.close()

    return resultado

def desasociarUsuario(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta quitar una asociación
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[DesasociarUsuarioPropiedad] ?, ?, ?, ?"

    datos = []
    for i in ['usuario', 'numeroFinca']:
        datos.append(str(informacion[i]))

    salida = cursor.execute(
        query,
        datos[0],
        datos[1],
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0
    }

    try:
        # Copia el código de salida del procedimiento
        # a lo que se retorna
        resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
        }

    cursor.commit()
    cursor.close()

    return resultado

def usuarioEsAdmin(consultante: str = ''):
    """
    Función que retorna el tipo de usuario
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerTipoDeUsuario] ?"

    salida = cursor.execute(query, consultante)

    resultado = False

    try:
        fila = salida.fetchone()
        if fila[0] != None and fila[0] == True:
            resultado = True
    except:
        resultado = False

    cursor.close()
    return resultado

def facturasDePropiedad(finca: str = '', consultante: str = ''):
    """
    Función que retorna las facturas de una propiedad dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerFacturasDePropiedad] ?,?"

    salida = cursor.execute(query, finca, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "fechaEmitida": fila[0],
                    "fechaVencida": fila[1],
                    "totalOriginal": str(fila[2]),
                    "totalAcumulado": str(fila[3]),
                    "estado": fila[4],
                    "referenciaPago": fila[5],
                    "pagada": fila[6]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def detallesDeFactura(finca: str = '', fecha: str = '', consultante: str = ''):
    """
    Función que retorna los detalles de una factura dada
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerFactura] ?,?,?"

    salida = cursor.execute(query, finca, fecha, consultante)

    resultado = {
        "status": 0,
        "results": [],
        "receipt": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "rubro": fila[0],
                    "monto": str(fila[1])
                })
        # Retorna el estado general de la factura en la segunda tabla
        salida.nextset()
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["receipt"].append({
                    "fechaEmitida": fila[0],
                    "fechaVencida": fila[1],
                    "totalOriginal": str(fila[2]),
                    "totalAcumulado": str(fila[3]),
                    "estado": fila[4],
                    "referenciaPago": fila[5],
                    "pagada": fila[6]
                })
        # Avanza a la tercera tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": [],
            "receipt": []
        }

    cursor.close()
    return resultado

def todosLosPagos(consultante: str = ''):
    """
    Función que retorna la lista completa de pagos
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPagos] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "fecha": fila[0],
                    "medio": fila[1],
                    "numeroReferencia": fila[2],
                    "totalPagado": str(fila[3])
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def detallesDePago(referencia: str = '', consultante: str = ''):
    """
    Función que retorna un comprobante de pago
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerPago] ?,?"

    salida = cursor.execute(query, referencia, consultante)

    resultado = {
        "status": 0,
        "receipt": [],
        "properties": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["receipt"].append({
                    "fecha": fila[0],
                    "medio": fila[1],
                    "numeroReferencia": fila[2],
                    "total": str(fila[3])
                })
        # Retorna el estado general de la factura en la segunda tabla
        salida.nextset()
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["properties"].append({
                    "finca": fila[0],
                    "fechaEmitida": fila[1],
                    "fechaVencida": fila[2],
                    "total": str(fila[3])
                })
        # Avanza a la tercera tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "receipt": [],
            "properties": []
        }

    cursor.close()
    return resultado

def hacerPago(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta crear una propiedad
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[PagarFacturas] ?, ?, ?, ?, ?"

    datos = []
    for i in ['fechaInicial', 'fechaFinal', 'finca']:
        datos.append(str(informacion[i]))

    print(query,
        datos[0],
        datos[1],
        int(datos[2]),
        consultante,
        consultante_ip)

    salida = cursor.execute(
        query,
        datos[0],
        datos[1],
        int(datos[2]),
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0,
        "receipt": None
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["receipt"] = fila[0]
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "receipt": None
        }

    cursor.commit()
    cursor.close()

    return resultado

def verEventos(fechaInicio: str = '', fechaFinal: str = '', consultante: str = ''):
    """
    Función que retorna la lista completa de eventos
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[VerEventos] ?, ?, ?"

    salida = cursor.execute(query, fechaInicio, fechaFinal, consultante)

    resultado = {
        "status": 0,
        "results": [],
        "dateRange": {}
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "entidad": fila[0],
                    "id": fila[1],
                    "jsonAntes": fila[2],
                    "jsonDespues": fila[3],
                    "time": fila[4].isoformat(),
                    "user": fila[5],
                    "IP": fila[6]
                })
        # Avanza a la segunda tabla (con el rango de fechas)
        if salida.nextset():
            # Copia las fechas
            for fila in salida.fetchall():
                # Para cada fila de la salida
                resultado["dateRange"] = {
                    "start": fila[0],
                    "end": fila[1]
                }
            
        # Avanza a la tercera tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": [],
            "dateRange": {}
        }

    cursor.close()
    return resultado

def tiposDeDocumentos(consultante: str = ''):
    """
    Función que retorna los diferentes tipos de documentos de identidad
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)
    query = "EXEC [dbo].[ObtenerTiposId] ?"

    salida = cursor.execute(query, consultante)

    resultado = {
        "status": 0,
        "results": []
    }

    try:
        for fila in salida.fetchall():
            # Para cada fila de la salida
            if fila[0] != None:
                resultado["results"].append({
                    "nombre": fila[0]
                })
        # Avanza a la segunda tabla de salida (con el código de salida)
        if salida.nextset():
            # Copia el código de salida del procedimiento
            # a lo que se retorna
            resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
            "results": []
        }

    cursor.close()
    return resultado

def crearPersona(informacion: dict = {}, consultante: str = '', consultante_ip: str = ''):
    """
    Función que intenta crear una propiedad
    consultante = usuario que está haciendo la consulta
    """

    cursor = odbc.connect(CONNECTION_STRING)

    query = "EXEC [dbo].[crearPersona] ?, ?, ?, ?, ?, ?, ?, ?"

    datos = []
    for i in ['tipoId', 'nombre', 'id', 'telefono1', 'telefono2', 'email']:
        datos.append(str(informacion[i]))

    salida = cursor.execute(
        query,
        datos[0],
        datos[1],
        datos[2],
        datos[3],
        datos[4],
        datos[5],
        consultante,
        consultante_ip
        )
    
    resultado = {
        "status": 0
    }

    try:
        # Copia el código de salida del procedimiento
        # a lo que se retorna
        resultado["status"] = salida.fetchone()[0]
    except:
        # Ocurrió un error
        resultado = {
            "status": 500,      # 500 = error interno del servidor
        }

    cursor.commit()
    cursor.close()

    return resultado