
--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado



ALTER PROCEDURE [dbo].[InsertarPropiedadesXml]
						@inxmlData AS XML = '',
						@inFechaOperacion AS DATE = GETDATE

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @temp_Propiedad TABLE 
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    -- Otras columnas
	    NumeroFinca INT NOT NULL,
		MetrosCuadrados INT NOT NULL,
		tipoUsoPropiedad varchar(32) NOT NULL,
		tipoZonaPropiedad varchar(32) NOT NULL,
		NumeroMedidor int NOT NULL,
		ValorFiscal BIGINT NOT NULL,
		FechaOperacion DATE
	);

	DECLARE @hdoc int;
	EXEC sp_xml_preparedocument @hdoc OUTPUT, @inxmlData;
	
	INSERT INTO @temp_Propiedad (NumeroFinca, MetrosCuadrados, tipoUsoPropiedad, tipoZonaPropiedad, NumeroMedidor, ValorFiscal)
	SELECT NumeroFinca, MetrosCuadrados, tipoUsoPropiedad, tipoZonaPropiedad, NumeroMedidor, ValorFiscal
	FROM OPENXML(@hdoc, 'Operacion/Propiedades/Propiedad', 1)
	WITH 
	(
		NumeroFinca INT,
		MetrosCuadrados INT,
		tipoUsoPropiedad varchar(32),
		tipoZonaPropiedad varchar(32),
		NumeroMedidor int,
		ValorFiscal BIGINT
	);
	UPDATE @temp_Propiedad
	SET FechaOperacion = @inFechaOperacion;

	DECLARE @idempezar INT;
	DECLARE @idmax INT;

	SET @idempezar =
	(
	SELECT TOP 1 id
	FROM [dbo].[Propiedad] 
	ORDER BY ID DESC
	)

	IF @idempezar IS NULL
	BEGIN
	SET @idempezar = 0;
	END

	-- realizamos la insercion de las propiedades del xml
	INSERT INTO [dbo].[Propiedad] ([idTipoUsoPropiedad], [idTipoZona], [numeroFinca], [area], [valorFiscal], [fechaRegistro])
	SELECT tup.id, tz.id, NumeroFinca, MetrosCuadrados, ValorFiscal, FechaOperacion
	FROM @temp_Propiedad AS tp
	INNER JOIN [dbo].[TipoUsoPropiedad] AS tup ON tp.tipoUsoPropiedad = tup.nombre
	INNER JOIN [dbo].[TipoZona] AS tz ON tp.tipoZonaPropiedad = tz.nombre

	SET @idmax = 
	(
	SELECT TOP 1 id 
	FROM [dbo].[Propiedad] 
	ORDER BY ID DESC
	)

	-- empezamos a generarles a cada propiedad nueva sus conceptos de cobro

	--y para ello ajustaremos "el trigger" para que sirva como SP
	
	DECLARE @temp_id INT;
	DECLARE @temp_idTipoUsoPropiedad INT;
	DECLARE @temp_idTipoZona INT;
	DECLARE @temp_numeroFinca INT;
	DECLARE @temp_area INT;
	DECLARE @temp_NumeroMedidor int;
	DECLARE @temp_valorFiscal BIGINT;
	DECLARE @temp_fechaRegistro DATE;

	WHILE @idempezar <= @idmax
	BEGIN

	--asignacion de valores a la tabla temporal
	SELECT @temp_id = p.id,
	@temp_idTipoUsoPropiedad = p.idTipoUsoPropiedad,
	@temp_idTipoZona = p.idTipoZona,
	@temp_numeroFinca = p.numeroFinca,
	@temp_area = p.area,
	@temp_valorFiscal = p.valorFiscal,
	@temp_fechaRegistro = p.fechaRegistro
	FROM [dbo].[Propiedad] p
	WHERE @idempezar = p.id

	SELECT @temp_NumeroMedidor = tp.NumeroMedidor
	FROM @temp_Propiedad tp
	WHERE @temp_numeroFinca = tp.NumeroFinca

	IF (@temp_id IS NOT NULL AND @temp_NumeroMedidor IS NOT NULL)
	BEGIN
	EXEC [dbo].[asignacionConceptosCobros] @temp_id, @temp_idTipoUsoPropiedad, @temp_idTipoZona, @temp_numeroFinca, @temp_area, @temp_NumeroMedidor, @temp_valorFiscal, @temp_fechaRegistro
	END

	SET @idempezar = @idempezar + 1;

	END

	EXEC sp_xml_removedocument @hdoc

	SET NOCOUNT OFF;
END