
--SP insercion de propiedades mediante xml
-- inserta todas las personas del nodo entregado



ALTER PROCEDURE [dbo].[InsertarPropiedadesXml]
						@hdoc INT,
						@inFechaOperacion DATE

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @temp_Propiedad TABLE 
	(
	    -- Llaves
	    id INT PRIMARY KEY IDENTITY(1,1),
	    -- Otras columnas
	    NumeroFinca INT NOT NULL,
		MetrosCuadrados INT NOT NULL,
		tipoUsoPropiedad varchar(32) NOT NULL,
		tipoZonaPropiedad varchar(32) NOT NULL,
		NumeroMedidor int NOT NULL,
		ValorFiscal BIGINT NOT NULL,
        consumoAcumulado MONEY NOT NULL,
        acumuladoUltimaFactura MONEY NOT NULL,
		FechaOperacion DATE
	);
	
	INSERT INTO @temp_Propiedad (
				NumeroFinca, 
				MetrosCuadrados, 
				tipoUsoPropiedad, 
				tipoZonaPropiedad, 
				NumeroMedidor, 
				ValorFiscal,
                consumoAcumulado,
                acumuladoUltimaFactura,
				FechaOperacion)
	SELECT NumeroFinca, 
		   MetrosCuadrados, 
		   tipoUsoPropiedad, 
		   tipoZonaPropiedad, 
		   NumeroMedidor, 
		   ValorFiscal,
           M3AcumuladoAgua,
           M3AcumuladosUltimoFactura,
		   @inFechaOperacion
	FROM OPENXML(@hdoc, 'Operacion/Propiedades/Propiedad', 1)
	WITH 
	(
		NumeroFinca INT,
		MetrosCuadrados INT,
		tipoUsoPropiedad varchar(32),
		tipoZonaPropiedad varchar(32),
		NumeroMedidor int,
		ValorFiscal BIGINT,
        M3AcumuladoAgua MONEY,
        M3AcumuladosUltimoFactura MONEY
	);

	-- realizamos la insercion de las propiedades del xml
	INSERT INTO [dbo].[Propiedad] (
				[idTipoUsoPropiedad], 
				[idTipoZona], 
				[numeroFinca], 
				[area], 
				[valorFiscal],
                [consumoAcumulado],
                [acumuladoUltimaFactura],
				[fechaRegistro])
	SELECT tup.id, 
		   tz.id, 
		   NumeroFinca, 
		   MetrosCuadrados, 
		   ValorFiscal,
           consumoAcumulado,
           acumuladoUltimaFactura,
		   FechaOperacion
	FROM @temp_Propiedad AS tp
	INNER JOIN [dbo].[TipoUsoPropiedad] AS tup ON tp.tipoUsoPropiedad = tup.nombre
	INNER JOIN [dbo].[TipoZona] AS tz ON tp.tipoZonaPropiedad = tz.nombre

    -- Se agregan los medidores para las propiedades
    INSERT INTO [dbo].[AguaDePropiedad] (
				[id], 
				[numeroMedidor], 
				[consumoAcumulado])
    SELECT CCdP.[id], 
		   TP.NumeroMedidor, 
		   0
    FROM [dbo].[Propiedad] P
    INNER JOIN [dbo].[ConceptoCobroDePropiedad] CCdP ON CCdP.idPropiedad = P.id
    INNER JOIN @temp_Propiedad TP ON P.numeroFinca = TP.NumeroFinca
    WHERE CCdP.idConceptoCobro = 1;         -- 1 = agua

	SET NOCOUNT OFF;
END