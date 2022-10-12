

USE [proyecto]

-- creamos la tabla que almacena los nodos xml

-- mediante esta tabla tenemos acceso a todos los nodos del xml
-- y a que dia pertenecen
BEGIN TRY
	CREATE TABLE dbo.InformacionXml
	(
	id INT  PRIMARY KEY IDENTITY(1,1),
	Fecha DATE,
	xmlData XML
	)
END TRY
BEGIN CATCH
	
	DELETE dbo.InformacionXml;
	DBCC CHECKIDENT ([InformacionXml], RESEED, 0);

END CATCH

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
INSERT INTO dbo.InformacionXml(Fecha, xmlData)
(
	SELECT t.Fecha,q.xmlData
	FROM @otra AS t, @otro AS q
	WHERE t.id = q.id
)

EXEC sp_xml_removedocument @hdoc

-- la tabla dbo.InformacionXml tiene la fecha y el nodo xml al cual se debe referir para sacar el resto de la informacion

DECLARE @FechaOperacion DATE;
DECLARE @contador INT;
DECLARE @maximo INT;
SET @contador = 1;
SELECT @maximo = COUNT(0) FROM dbo.InformacionXml;

-- iteramos atravez de todos los nodos del xml
WHILE (@contador <= @maximo)
BEGIN

	--seleccionamos un nodo para procesar
	SELECT @inDatos = t.xmlData, @FechaOperacion = t.Fecha
	FROM dbo.InformacionXml AS t
	WHERE t.id = @contador

	PRINT 'Ciclo ';PRINT @contador;
	EXEC dbo.InsertarPersonasXml @inDatos
	EXEC [dbo].[InsertarPropiedadesXml] @inDatos, @FechaOperacion
	EXEC [dbo].[AsociacionPersonaPropiedadXml] @inDatos, @FechaOperacion
	EXEC [dbo].[(Des)InsertarUsuariosXml] @inDatos, @FechaOperacion
	EXEC [dbo].[AsociacionUsuarioPropiedadXml] @inDatos, @FechaOperacion
	EXEC [dbo].[InsertarLecturaMedidorXml] @inDatos, @FechaOperacion

	SET @contador = @contador +1
END