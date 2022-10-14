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