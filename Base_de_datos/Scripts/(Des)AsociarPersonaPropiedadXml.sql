--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado



ALTER PROCEDURE [dbo].[AsociacionPersonaPropiedadXml]
						@inxmlData AS XML = '',
						@inFechaOperacion AS DATE = GETDATE

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @temp_PersonasyPropiedades TABLE
	(
	    -- Llaves
	    id INT NOT NULL IDENTITY(1,1),
	    ValorDocumentoIdentidad BIGINT NOT NULL,
	    NumeroFinca INT NOT NULL,
		TipoAsociacion varchar(32) NOT NULL,
		FechaOperacion DATE
	
	);

	DECLARE @hdoc int;
	EXEC sp_xml_preparedocument @hdoc OUTPUT, @inxmlData;
	
	INSERT INTO @temp_PersonasyPropiedades (ValorDocumentoIdentidad, NumeroFinca, TipoAsociacion)
	SELECT ValorDocumentoIdentidad, NumeroFinca, TipoAsociacion
	FROM OPENXML(@hdoc, 'Operacion/PersonasyPropiedades/PropiedadPersona', 1)
	WITH 
	(
		ValorDocumentoIdentidad BIGINT,
		NumeroFinca INT,
		TipoAsociacion varchar(32)
	);
	UPDATE @temp_PersonasyPropiedades
	SET FechaOperacion = @inFechaOperacion;

	--inicializamos las relaciones que se indican como Agregar
	INSERT INTO [dbo].[PropietarioDePropiedad]([idPersona], [idPropiedad], [fechaInicio])
	SELECT per.id, pro.id, tpp.FechaOperacion
	FROM @temp_PersonasyPropiedades AS tpp
	INNER JOIN [dbo].[Persona] AS per ON tpp.ValorDocumentoIdentidad = per.valorDocumentoId
	INNER JOIN [dbo].[Propiedad] AS pro ON pro.numeroFinca = tpp.NumeroFinca
	WHERE tpp.TipoAsociacion = 'Agregar'


	--finalizamos las relaciones que se indican como Eliminar
	UPDATE pdp
	SET    pdp.fechaFin = @inFechaOperacion
	FROM   [dbo].[PropietarioDePropiedad] AS pdp
	INNER JOIN [dbo].[Propiedad] AS pro ON pdp.idPropiedad = pro.id
	INNER JOIN @temp_PersonasyPropiedades AS pyp ON pyp.NumeroFinca = pro.numeroFinca
	WHERE  pyp.TipoAsociacion = 'Eliminar'
	AND pdp.fechaInicio IS NOT NULL

	EXEC sp_xml_removedocument @hdoc

	SELECT * FROM @temp_PersonasyPropiedades

	SET NOCOUNT OFF;
END