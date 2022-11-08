
USE proyecto
GO
-- SP que inserta crea la factura de la propiedad
-- no incluye en el cobro  

ALTER PROCEDURE [dbo].[GenerarFacturaXML]
						@inFechaOperacion DATE
AS
BEGIN

	DECLARE @costoPatentes AS INT;
	DECLARE @costoParques AS INT;
	DECLARE @procesando AS INT = -1;
	DECLARE @error AS INT = -2;

	DECLARE @sumatoriaConceptos TABLE --donde almacenaremos la sumatoria de los conceptos
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    idFactura INT NOT NULL,
		idPropieda INT NOT NULL,
		Monto INT NOT NULL
	)

	SET NOCOUNT ON;	
	
	-- en @generamos una factura incompleta de todas las propiedades a las que les deberemos generar una factura

	INSERT INTO FACTURA(idPropiedad, 
						idEstadoFactura, 
						idPago, 
						fechaGeneracion, 
						fechaVencimiento, 
						totalOriginal, 
						totalActual
						)
	SELECT p.id, 
		   1, 
		   NULL, 
		   @inFechaOperacion, 
		   DATEADD(DAY,8,@inFechaOperacion), --8 dias antes de vencimiento
		   @procesando,
		   @procesando
	FROM Propiedad p
	WHERE p.fechaRegistro < @inFechaOperacion -- fecha actual es mayor que la de registros
	AND DAY(DATEADD(MONTH,(MONTH(@inFechaOperacion)- MONTH(p.fechaRegistro)),p.fechaRegistro)) = DAY(@inFechaOperacion) -- dia mas cernano del siguiente mes


	-- al ya tener un id para la factura, podemos generar el DetalleDeCobro
	-- para encontrar la factura, indicamos el idPropiedad y totalOriginal = -1

	--obtenemos el costo de patentes
	SELECT @costoPatentes = ccp.valorPatente
	FROM ConceptoCobro cc
	INNER JOIN ConceptoCobroPatente ccp ON ccp.id = cc.id

	--obtenemos el costo de parques
	SELECT @costoParques = ccp.valorFijo
	FROM ConceptoCobro cc
	INNER JOIN ConceptoCobroParques ccp ON ccp.id = cc.id

	INSERT INTO DetalleConceptoCobro(idFactura, 
									 idConceptoCobro, 
									 monto)
	SELECT f.id, 
		   ccdp.idConceptoCobro, 
		   CASE
			   WHEN ccdp.idConceptoCobro = 1 THEN CASE --formula cobro del agua
													WHEN (p.consumoAcumulado-p.acumuladoUltimaFactura)*cca.montoTracto>cca.montoMinimo
													THEN (p.consumoAcumulado-p.acumuladoUltimaFactura)*cca.montoTracto/tpcc.cantidadMeses
													ELSE cca.montoMinimo/tpcc.cantidadMeses
												  END
			   WHEN ccdp.idConceptoCobro = 2 THEN CAST(p.valorFiscal AS MONEY)*ccip.valorPorcentual/tpcc.cantidadMeses--formula propiedad
			   WHEN ccdp.idConceptoCobro = 3 THEN CASE --formula de la basura
													WHEN p.area<=ccb.areaMinima THEN ccb.montoMinimo/tpcc.cantidadMeses
													ELSE (ccb.montoMinimo+ccb.montoTracto*((p.area%ccb.areaTracto)-(ccb.areaMinima%ccb.areaTracto)))/tpcc.cantidadMeses
												  END
			   WHEN ccdp.idConceptoCobro = 4 THEN @costoPatentes/tpcc.cantidadMeses--patente
			   WHEN ccdp.idConceptoCobro = 7 THEN @costoParques/tpcc.cantidadMeses--parques
			   ELSE @error
		   END
	FROM Factura f
	INNER JOIN Propiedad p ON p.id = f.idPropiedad -- obtenemos los atributos de las propiedades
	INNER JOIN ConceptoCobroDePropiedad ccdp ON ccdp.idPropiedad = p.id -- obtenemos los ConceptosDeCobro asociados a las propiedades
	INNER JOIN ConceptoCobro cc ON cc.id = ccdp.idConceptoCobro -- vinculo para obtener precios de los impuestos
	INNER JOIN TipoPeriodoConceptoCobro tpcc ON tpcc.id = cc.idTipoPeriodoConceptoCobro -- obtenemos cada cuanto debe ser calculado
	LEFT JOIN ConceptoCobroBasura ccb ON ccb.id = cc.id -- precio de la basura
	LEFT JOIN ConceptoCobroImpuestoPropiedad ccip ON ccip.id = cc.id -- precio impuesto propiedad
	LEFT JOIN ConceptoCobroAgua cca ON cca.id = cc.id -- precio agua
	WHERE f.totalOriginal = @procesando

	-- llegados a este punto DetalleConceptoCobro tiene el id de la factura, el id del cobro y el monto a cobrar

	-- para poder realizar la sumatoria de los montos utilizamos la tabla temporal @sumatoriaConceptos

	INSERT INTO @sumatoriaConceptos(idFactura,Monto)
	SELECT dcc.idFactura, SUM(dcc.monto)
	FROM DetalleConceptoCobro dcc
	INNER JOIN Factura f ON dcc.idFactura = f.id
	WHERE totalOriginal = @procesando
	GROUP BY dcc.idFactura
	
	--recordemos que:
	-- para encontrar la factura, indicamos el idPropiedad y totalOriginal = @procesando
	-- pero como ya tenemos el id de la factura entonces con eso basta
	Update f
	SET f.totalOriginal = sc.Monto,
		f.totalActual = sc.Monto
	FROM Factura f
	INNER JOIN @sumatoriaConceptos sc ON sc.idFactura = f.id
	WHERE totalOriginal = @procesando -- sobrando, pero lo dejamos por seguridad
	



	SET NOCOUNT OFF;
END