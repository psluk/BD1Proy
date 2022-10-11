
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

	INSERT INTO [dbo].[Propiedad] ([idTipoUsoPropiedad], [idTipoZona], [numeroFinca], [area], [valorFiscal], [fechaRegistro])
	SELECT tup.id, tz.id, NumeroFinca, MetrosCuadrados, ValorFiscal, FechaOperacion
	FROM @temp_Propiedad AS tp
	INNER JOIN [dbo].[TipoUsoPropiedad] AS tup ON tp.tipoUsoPropiedad = tup.nombre
	INNER JOIN [dbo].[TipoZona] AS tz ON tp.tipoZonaPropiedad = tz.nombre
	EXEC sp_xml_removedocument @hdoc

	--la insercion en Propiedad implica muchisimas cosas. las cuales deberan ser tabajadas. entre estas entan
	-- que deben ser trabajadas con triggers:
	-- crear (una o varias) entrada de [dbo].[ConceptoCobroDePropiedad] cada una de estas requieren crear
	-- [dbo].[ConceptoCobro]que ocupara info de la propiedad para preguntarle a los catalogos:
	-- 
	-- [dbo].[ConceptoCobroParques], [dbo].[ConceptoCobroBasura], [dbo].[ConceptoCobroInteresesMoratorios], [dbo].[ConceptoCobroImpuestoPropiedad],
	-- [dbo].[ConceptoCobroReconexionAgua], [dbo].[ConceptoCobroAgua]
	-- 
	-- cuanto hay que cobrar, que tipo de cobro es(preguntandole a [dbo].[TipoMontoConceptoCobro]) y de que periodo es (preguntadole a [dbo].[TipoPeriodoConceptoCobro])
	--
	-- para la creacion de [dbo].[AguaDePropiedad] esta se asocia unicamnete con una entrada en [dbo].[ConceptoCobroDePropiedad] y del tipo [dbo].[ConceptoCobroAgua]



	SELECT * FROM @temp_Propiedad

	SET NOCOUNT OFF;
END