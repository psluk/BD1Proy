USE proyecto
GO
--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado

ALTER PROCEDURE [dbo].[InsertarLecturaMedidorXml]
						@hdoc INT,
						@inFechaOperacion DATE
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
		ConsumoMovimiento MONEY,
        ConsumoAnterior MONEY
	
	);
	
	
	INSERT INTO @temp_Lecturas (NumeroMedidor, TipoMovimiento, Valor, FechaOperacion)
	SELECT NumeroMedidor, TipoMovimiento, Valor, @inFechaOperacion
	FROM OPENXML(@hdoc, 'Operacion/Lecturas/LecturaMedidor', 1)
	WITH 
	(
	    NumeroMedidor int,
		TipoMovimiento varchar(32),
		Valor int
		
	);

	-- obtenemos el ConsumoAcumulado viejo segun el numero de medidor
	-- se asume que el numero de medidor es unico, ya que es el unico identificador
	UPDATE tl
	SET    tl.ConsumoAnterior = adp.consumoAcumulado
	FROM  @temp_Lecturas AS tl
	INNER JOIN [dbo].[AguaDePropiedad] AS adp ON tl.NumeroMedidor = adp.numeroMedidor

	-- obtenemos el ConsumoMovimiento


	--Lectura de Medidor
	UPDATE tl
	SET    ConsumoMovimiento = (Valor - ConsumoAnterior)
	FROM @temp_Lecturas AS tl
	WHERE ConsumoAnterior IS NOT NULL
	AND tl.TipoMovimiento = 'Lectura'

	--Ajuste Credito
	UPDATE tl
	SET    ConsumoMovimiento = Valor, ConsumoAcumulado = ConsumoAnterior + Valor
	FROM @temp_Lecturas AS tl
	WHERE ConsumoAnterior IS NOT NULL
	AND (tl.TipoMovimiento = 'Ajuste Credito')

    --Ajuste Debito
	UPDATE tl
	SET    ConsumoMovimiento = -Valor, ConsumoAcumulado = ConsumoAnterior - Valor
	FROM @temp_Lecturas AS tl
	WHERE ConsumoAnterior IS NOT NULL
	AND (tl.TipoMovimiento = 'Ajuste Debito')


	-- insertamos los valores en la tabla Movimiento Consumo, se puede optimizar
	INSERT INTO [dbo].[MovimientoConsumo] ([idTipoMovimiento], [idAguaDePropiedad], [fecha], [consumoMovimiento], [consumoAcumulado])
	SELECT tmc.id, adp.id, tl.FechaOperacion, tl.ConsumoMovimiento, tl.ConsumoAcumulado
	FROM @temp_Lecturas AS tl
	INNER JOIN [dbo].[TipoMovimientoConsumo] tmc ON tl.TipoMovimiento = tmc.nombre
	INNER JOIN [dbo].[AguaDePropiedad] adp ON tl.NumeroMedidor = adp.numeroMedidor
	WHERE tl.ConsumoAcumulado IS NOT NULL


	--ahora actualizamos el ConsumoAcumulado en [dbo].[AguaDePropiedad]

	UPDATE adp
	SET adp.consumoAcumulado = tl.ConsumoAcumulado
	FROM [dbo].[AguaDePropiedad] AS adp
	INNER JOIN @temp_Lecturas tl ON adp.numeroMedidor = tl.NumeroMedidor
	WHERE tl.ConsumoAcumulado IS NOT NULL

	SET NOCOUNT OFF;
END