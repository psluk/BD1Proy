USE proyecto
GO
--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado

ALTER PROCEDURE [dbo].[InsertarLecturaMedidorXml]
						@inxmlData AS XML = '',
						@inFechaOperacion AS DATE = GETDATE
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @temp_Lecturas TABLE
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    NumeroMedidor int NOT NULL,
		TipoMovimiento varchar(32) NOT NULL,
		Valor int NOT NULL,
		FechaOperacion DATE,
		ConsumoAcumulado MONEY,
		ConsumoMovimiento MONEY
	
	);
	DECLARE @hdoc int;
	EXEC sp_xml_preparedocument @hdoc OUTPUT, @inxmlData;
	
	
	INSERT INTO @temp_Lecturas (NumeroMedidor, TipoMovimiento, Valor)
	SELECT NumeroMedidor, TipoMovimiento, Valor
	FROM OPENXML(@hdoc, 'Operacion/Lecturas/LecturaMedidor', 1)
	WITH 
	(
	    NumeroMedidor int,
		TipoMovimiento varchar(32),
		Valor int
		
	);
	UPDATE @temp_Lecturas
	SET FechaOperacion = @inFechaOperacion;

	-- obtenemos el ConsumoAcumulado viejo segun el numero de medidor
	-- se asume que el numero de medidor es unico, ya que es el unico identificador
	UPDATE tl
	SET    tl.ConsumoAcumulado = adp.consumoAcumulado
	FROM  @temp_Lecturas AS tl
	INNER JOIN [dbo].[AguaDePropiedad] AS adp ON tl.NumeroMedidor = adp.numeroMedidor

	-- obtenemos el ConsumoMovimiento


	--Lectura de Medidor
	UPDATE tl
	SET    ConsumoMovimiento = (Valor - ConsumoAcumulado)
	FROM @temp_Lecturas AS tl
	WHERE ConsumoAcumulado IS NOT NULL
	AND tl.TipoMovimiento = 'Lectura'

	--Ajuste Credito o Ajuste Debito
	UPDATE tl
	SET    ConsumoMovimiento = Valor
	FROM @temp_Lecturas AS tl
	WHERE ConsumoAcumulado IS NOT NULL
	AND (tl.TipoMovimiento = 'Ajuste Credito' OR tl.TipoMovimiento = 'Ajuste Debito')


	-- insertamos los valores en la tabla Movimiento Consumo, se puede optimizar
	INSERT INTO [dbo].[MovimientoConsumo] ([idTipoMovimiento], [idAguaDePropidad], [fecha], [consumoMovimiento], [consumoAcumulado])
	SELECT tmc.id, adp.id, tl.FechaOperacion, tl.ConsumoMovimiento, tl.ConsumoAcumulado
	FROM @temp_Lecturas AS tl
	INNER JOIN [dbo].[TipoMovimientoConsumo] tmc ON tl.TipoMovimiento = tmc.nombre
	INNER JOIN [dbo].[AguaDePropiedad] adp ON tl.NumeroMedidor = adp.numeroMedidor
	WHERE tl.ConsumoAcumulado IS NOT NULL


	--ahora actualizamos el ConsumoAcumumalo en [dbo].[AguaDePropiedad]

	--Ajuste de Credito o Lectura
	UPDATE adp
	SET adp.consumoAcumulado = adp.consumoAcumulado + tl.ConsumoMovimiento
	FROM [dbo].[AguaDePropiedad] AS adp
	INNER JOIN @temp_Lecturas tl ON adp.numeroMedidor = tl.NumeroMedidor
	WHERE tl.ConsumoAcumulado IS NOT NULL
	AND (tl.TipoMovimiento = 'Ajuste Credito' OR tl.TipoMovimiento = 'Lectura')

	--Ajuste de Credito o Lectura
	UPDATE adp
	SET adp.consumoAcumulado = adp.consumoAcumulado - tl.ConsumoMovimiento
	FROM [dbo].[AguaDePropiedad] AS adp
	INNER JOIN @temp_Lecturas tl ON adp.numeroMedidor = tl.NumeroMedidor
	WHERE tl.ConsumoAcumulado IS NOT NULL
	AND tl.TipoMovimiento = 'Ajuste Debito'

	EXEC sp_xml_removedocument @hdoc

	--SELECT * FROM @temp_Lecturas

	SET NOCOUNT OFF;
END