

USE [proyecto]

DECLARE @informacionXML TABLE
(
id INT  PRIMARY KEY IDENTITY(1,1),
Fecha DATE,
xmlData XML
)

--tabla donde se almacena el xml completo
DECLARE @tmp TABLE 
(
	xmlData XML
)
--insertamos el documento xml para poder trabajar con el 
INSERT INTO @tmp(xmlData)
(
SELECT CAST(MY_XML AS xml) AS hola
      FROM OPENROWSET(BULK 'D:\Personal\TEC\Universidad\2022-6-2\base\servidores sql\proyecto\BD1Proy\Base_de_datos\Archivos XML\Operaciones.xml', SINGLE_BLOB) AS T(MY_XML)
)

DECLARE @inDatos xml;
SELECT @inDatos = C
FROM OPENROWSET (BULK 'D:\Personal\TEC\Universidad\2022-6-2\base\servidores sql\proyecto\BD1Proy\Base_de_datos\Archivos XML\Operaciones.xml', SINGLE_BLOB) AS inDatos(C);
DECLARE @hdoc int
EXEC sp_xml_preparedocument @hdoc OUTPUT, @inDatos;


--tabla donde se almacena cada nodo operacion
DECLARE @otro TABLE 
(
	id INT  PRIMARY KEY IDENTITY(1,1),
	xmlData XML
)
--insertamos los nodos en la tabla de nodos
INSERT INTO @otro(xmlData)
(
	SELECT x.Operacion.query('.') Operacion
	FROM @tmp t
	CROSS APPLY t.xmlData.nodes('Datos/Operacion') x(Operacion)
)

--tabla donde se almacena cada fecha de operacion
DECLARE @otra TABLE 
(
	id INT  PRIMARY KEY IDENTITY(1,1),
	Fecha DATE
)
--insertamos la fechas en la tabla de fechas
INSERT INTO @otra(Fecha)
(
	SELECT Fecha
	FROM OPENXML (@hdoc, 'Datos/Operacion' , 1)
	WITH
	(
		Fecha date
	)
)

--unificamos las fechas y sus nodos en una misma tabla
INSERT INTO @informacionXML(Fecha, xmlData)
(
	SELECT t.Fecha,q.xmlData
	FROM @otra AS t, @otro AS q
	WHERE t.id = q.id
)

EXEC sp_xml_removedocument @hdoc

-- la tabla @informacionXML tiene la fecha y el nodo xml al cual se debe referir para sacar el resto de la informacion

DECLARE @FechaOperacion DATE;
DECLARE @contador INT;
DECLARE @maximo INT;
SET @contador = 1;
SELECT @maximo = COUNT(0) FROM @informacionXML;

-- iteramos a trav�s de todos los nodos del xml
WHILE (@contador <= @maximo)
BEGIN
	--seleccionamos un nodo para procesar
	SELECT @inDatos = t.xmlData, @FechaOperacion = t.Fecha
	FROM @informacionXML AS t
	WHERE t.id = @contador

    -- Se carga el XML de la operaci�n en memoria
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @inDatos;

	EXEC dbo.InsertarPersonasXml @hdoc
	EXEC [dbo].[InsertarPropiedadesXml] @hdoc, @FechaOperacion
	EXEC [dbo].[AsociacionPersonaPropiedadXml] @hdoc, @FechaOperacion
	EXEC [dbo].[(Des)InsertarUsuariosXml] @hdoc, @FechaOperacion
	EXEC [dbo].[AsociacionUsuarioPropiedadXml] @hdoc, @FechaOperacion
	EXEC [dbo].[InsertarLecturaMedidorXml] @hdoc, @FechaOperacion

    -- Se libera de la memoria
    EXEC sp_xml_removedocument @hdoc;

	SET @contador = @contador +1
END;