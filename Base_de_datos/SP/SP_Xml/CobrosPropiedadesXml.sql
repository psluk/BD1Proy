
USE proyecto
GO

ALTER PROCEDURE [dbo].[asignacionConceptosCobros]
		@id INT,
		@idTipoUsoPropiedad INT,
		@idTipoZona INT,
		@numeroFinca INT,
		@area INT,
		@NumeroMedidor INT,
		@valorFiscal BIGINT,
		@fechaRegistro DATE
		
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @demomento TABLE(
		
		id INT NOT NULL,
		idTipoUsoPropiedad INT,
		idTipoZona INT,
		numeroFinca INT,
		area INT,
		NumeroMedidor INT,
		valorFiscal BIGINT,
		fechaRegistro DATE
	
	);
	INSERT INTO @demomento(id,idTipoUsoPropiedad,idTipoZona,numeroFinca,area,NumeroMedidor,valorFiscal,fechaRegistro)
	VALUES(@id,@idTipoUsoPropiedad,@idTipoZona,@numeroFinca,@area,@NumeroMedidor,@valorFiscal,@fechaRegistro);



	-- hay que realizar una nueva insercion por cada tipo de ConceptoCobro...

	--				  [dbo].[ConceptoCobroBasura] no aplica para zona agricola
	DECLARE @tempNumero INT;
	DECLARE @temp TABLE(
	
		id INT  PRIMARY KEY IDENTITY(1,1),
	    numero INT NOT NULL,
		nombre VARCHAR(32) NOT NULL,
		idPropiedad INT
	);


	--En la zona agricola no hay impuesto de recoleccion de basura
	SELECT @tempNumero = cc.id
	FROM [dbo].[ConceptoCobro] cc
	WHERE cc.nombre = 'Recoleccion Basura'

	-- obtenemos el id relacionado a Recoleccion Basura
	INSERT INTO @temp (numero, nombre)
	VALUES(@tempNumero, 'Agricola');
	
	INSERT INTO [dbo].[ConceptoCobroDePropiedad] ([idPropiedad], [idConceptoCobro], [fechaInicio])
	SELECT i.id, t.numero, i.fechaRegistro
	FROM @demomento i
	INNER JOIN [dbo].[TipoZona] tz ON i.idTipoZona = tz.id -- alineamos el idzona con su nombre
	INNER JOIN @temp t ON tz.nombre != t.nombre
	WHERE tz.nombre != 'Agricola'

	--________________________________________________________________________________________________

	DELETE @temp; -- limpiamos la tabla temporal

	--Solo en las zonas comerciales y residenciales hay limpieza de parques
	SELECT @tempNumero = cc.id
	FROM [dbo].[ConceptoCobro] cc
	WHERE cc.nombre = 'MantenimientoParques'
	-- obtenemos el id relacionado a MantenimientoParques
	INSERT INTO @temp (numero, nombre)
	VALUES(@tempNumero, 'Residencial')
	INSERT INTO @temp (numero, nombre)
	VALUES(@tempNumero, 'Zona comercial');
	

	INSERT INTO [dbo].[ConceptoCobroDePropiedad] ([idPropiedad], [idConceptoCobro], [fechaInicio])
	SELECT i.id, t.numero, i.fechaRegistro
	FROM @demomento i
	INNER JOIN [dbo].[TipoZona] tz ON i.idTipoZona = tz.id -- alineamos el idzona con su nombre
	INNER JOIN @temp t ON tz.nombre = t.nombre
	WHERE tz.nombre = 'Residencial'
	OR tz.nombre = 'Zona comercial'


	--________________________________________________________________________________________________

	DELETE @temp; -- limpiamos la tabla temporal
	 
	--aplicaremos el resto de impuestos
	INSERT INTO @temp (numero,nombre)
	SELECT cc.id, cc.nombre
	FROM [dbo].[ConceptoCobro] AS cc
	WHERE cc.nombre != 'MantenimientoParques'
	AND cc.nombre != 'Recoleccion Basura'

	SELECT @tempNumero = i.id
	FROM @demomento i

	UPDATE t
	SET t.idPropiedad = i.id
	FROM @temp t, @demomento i
	
--	impuesto insertados :[dbo].[ConceptoCobroImpuestoPropiedad] [dbo].[ConceptoCobroInteresesMoratorios] 
--					   [dbo].[ConceptoCobroReconexionAgua] [dbo].[ConceptoCobroAgua] [dbo].[ConceptoCobroPatente]
	INSERT INTO [dbo].[ConceptoCobroDePropiedad] ([idPropiedad], [idConceptoCobro], [fechaInicio])
	SELECT i.id, t.numero, i.fechaRegistro
	FROM @demomento i
	RIGHT JOIN @temp t ON t.idPropiedad = i.id
	WHERE t.nombre != 'MantenimientoParques'
	AND t.nombre != 'Recoleccion Basura'
    
	--________________________________________________________________________________________________

	--insertamos en AguadePropiedad
	INSERT INTO [dbo].[AguaDePropiedad]([id], [numeroMedidor], [consumoAcumulado])
	SELECT ccp.id,i.NumeroMedidor, 0
	FROM @demomento i
	INNER JOIN [dbo].[ConceptoCobroDePropiedad] ccp ON i.id = ccp.idPropiedad -- seleccion unicamente impuesto asociados a la propiedad
	INNER JOIN [dbo].[ConceptoCobro] cc ON ccp.idConceptoCobro = cc.id -- alineamos los cobros con su nombre
	WHERE cc.nombre = 'ConsumoAgua';

	SET NOCOUNT OFF;
END
GO
