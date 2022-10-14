--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado



ALTER PROCEDURE [dbo].[AsociacionPersonaPropiedadXml]
						@hdoc INT,
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
	INNER JOIN [dbo].[Persona] AS per ON pdp.idPersona = per.id
	INNER JOIN @temp_PersonasyPropiedades AS tpp ON tpp.ValorDocumentoIdentidad = per.idTipoDocumentoId
	WHERE  tpp.TipoAsociacion = 'Eliminar'
	AND pdp.fechaInicio IS NOT NULL 

	SET NOCOUNT OFF;
END