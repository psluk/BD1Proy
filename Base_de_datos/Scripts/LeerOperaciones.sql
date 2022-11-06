USE [proyecto]


--Declaracion de variables

DECLARE @VarPrincipalXML xml; -- variables contenedora del XML principal
DECLARE @hdoc int -- handler del xml leeido
DECLARE @FechaOperacion DATE; -- transporte de fecha a los SP
DECLARE @contador INT; -- Permite pasar por cada nodo del XML principal
DECLARE @maximo INT; -- indica el numero de repeticiones
DECLARE @fechaInicio AS DATE; -- indica el dia en el que se comineza
DECLARE @fechaFinal AS DATE; -- indica el ultimo dia

--Declaracion de tablas temporales

DECLARE @tabInformacionXML TABLE --Tabla relacionando nodo XML y Fecha
(
id INT  PRIMARY KEY IDENTITY(1,1),
Fecha DATE,
xmlData XML
)

DECLARE @tabPrincipalXML TABLE 
(
xmlData XML
) --Tabla contenedora del XML principal

DECLARE @tabNodosXML TABLE --Tabla para construir los nodo XML del XML principal
(
id INT  PRIMARY KEY IDENTITY(1,1),
xmlData XML
)

DECLARE @tabFechasXML TABLE --Tabla para construir las Fechas de cada nodo XML del XML principal
(
id INT  PRIMARY KEY IDENTITY(1,1),
Fecha DATE
)


--Inserciones


--Esto se realiza asi para poder usar "CROSS APPLY" y
--construir la tabla con los nodos
INSERT INTO @TabPrincipalXML(xmlData) --Insertamos el XMl principal en la Tabla contenedora
(
SELECT CAST(MY_XML AS xml) AS hola
      FROM OPENROWSET(BULK 'D:\Personal\TEC\Universidad\2022-6-2\base\servidores sql\proyecto\BD1Proy\Base_de_datos\Archivos XML\Operaciones.xml', SINGLE_BLOB) AS T(MY_XML)
) 

SELECT @VarPrincipalXML = t.xmlData -- Insertamos el XMl principal en la varible
FROM @TabPrincipalXML t
EXEC sp_xml_preparedocument @hdoc OUTPUT, @VarPrincipalXML; -- abrimos el xml

INSERT INTO @tabFechasXML(Fecha) --insertamos la fechas en la tabla de fechas
(
	SELECT Fecha
	FROM OPENXML (@hdoc, 'Datos/Operacion' , 1)
	WITH
	(
		Fecha date
	)
)

EXEC sp_xml_removedocument @hdoc

INSERT INTO @tabNodosXML(xmlData) --insertamos los nodos XML en la tabla de nodos
(
	SELECT x.Operacion.query('.') Operacion
	FROM @TabPrincipalXML t
	CROSS APPLY t.xmlData.nodes('Datos/Operacion') x(Operacion)
)


INSERT INTO @tabInformacionXML( --unificamos las fechas y sus nodos en una misma tabla
			Fecha, 
			xmlData) 
(
	SELECT t.Fecha,
		   q.xmlData
	FROM @tabFechasXML AS t, 
		 @tabNodosXML AS q
	WHERE t.id = q.id
)


-- la tabla @tabInformacionXML tiene la fecha y el nodo xml al cual se debe referir para sacar el resto de la informacion


SET @contador = 1; -- inicializamo el contador en la primera entrada
SELECT @maximo = COUNT(0) FROM @tabInformacionXML; --el valor de la ultima entrada
SELECT @fechaInicio = tab.Fecha FROM @tabInformacionXML tab WHERE tab.id = 1; 
SELECT @fechaFinal = tab.Fecha FROM @tabInformacionXML tab WHERE tab.id = @maximo;


-- iteramos a trav�s de todos los nodos del xml
WHILE (@contador <= @maximo)
BEGIN
	
	--validamos que los dias sean seguidos

	--seleccionamos un nodo para procesar y su fecha
	SELECT @VarPrincipalXML = t.xmlData, 
		   @FechaOperacion = t.Fecha
	FROM @tabInformacionXML AS t
	WHERE t.id = @contador

	IF @fechaInicio = @FechaOperacion -- se realizan las operaciones del dia
	BEGIN
	
		-- Se carga el XML de la operacion en memoria
		EXEC sp_xml_preparedocument @hdoc OUTPUT, @VarPrincipalXML;

		EXEC dbo.InsertarPersonasXml @hdoc
		EXEC [dbo].[InsertarPropiedadesXml] @hdoc, @FechaOperacion
		EXEC [dbo].[AsociacionPersonaPropiedadXml] @hdoc, @FechaOperacion
		EXEC [dbo].[(Des)InsertarUsuariosXml] @hdoc, @FechaOperacion
		EXEC [dbo].[AsociacionUsuarioPropiedadXml] @hdoc, @FechaOperacion
		EXEC [dbo].[InsertarLecturaMedidorXml] @hdoc, @FechaOperacion
		--EXEC [dbo].[PagoDeImpuestos] @hdoc, @FechaOperacionPagos
		

		-- Se libera de la memoria
		EXEC sp_xml_removedocument @hdoc;

		SET @contador = @contador +1 --aumentamos el contador

	END

	--realizamos las operaciones de todos los dia
	
	--Cortes @fechaInicio
	--Reconexiones @fechaInicio
	--Morosidad @fechaInicio
	
	SELECT @fechaInicio = DATEADD(DAY,1,@fechaInicio) -- aumentamos el dia en 1

END;