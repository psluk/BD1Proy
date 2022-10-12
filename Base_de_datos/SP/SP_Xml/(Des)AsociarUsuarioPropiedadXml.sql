--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado



ALTER PROCEDURE [dbo].[AsociacionUsuarioPropiedadXml]
						@inxmlData AS XML = '',
						@inFechaOperacion AS DATE = GETDATE

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @temp_UsuariosyPropiedades TABLE
	(
	    -- Llaves
	    id INT PRIMARY KEY IDENTITY(1,1),
	    ValorDocumentoIdentidad BIGINT NOT NULL,
	    NumeroFinca INT NOT NULL,
		TipoAsociacion varchar(32) NOT NULL,
		FechaOperacion DATE
	
	);

	DECLARE @hdoc int;
	EXEC sp_xml_preparedocument @hdoc OUTPUT, @inxmlData;
	
	INSERT INTO @temp_UsuariosyPropiedades (ValorDocumentoIdentidad, NumeroFinca, TipoAsociacion)
	SELECT ValorDocumentoIdentidad, NumeroFinca, TipoAsociacion
	FROM OPENXML(@hdoc, 'Operacion/PropiedadesyUsuarios/UsuarioPropiedad', 1)
	WITH 
	(
		ValorDocumentoIdentidad BIGINT,
		NumeroFinca INT,
		TipoAsociacion varchar(32)
	);
	UPDATE @temp_UsuariosyPropiedades
	SET FechaOperacion = @inFechaOperacion;

	--inicializamos las relaciones que se indican como Agregar
	INSERT INTO [dbo].[UsuarioDePropiedad]([idUsuario], [idPropiedad], [fechaInicio])
	SELECT u.id, pro.id, tup.FechaOperacion
	FROM @temp_UsuariosyPropiedades AS tup
	INNER JOIN [dbo].[Persona] AS per ON tup.ValorDocumentoIdentidad = per.valorDocumentoId --se obtiene el id del documento identidad
	INNER JOIN [dbo].[Usuario] AS u ON u.idPersona = per.id -- se obtiene el id del usuario usando el id de la persona
	INNER JOIN [dbo].[Propiedad] AS pro ON tup.NumeroFinca = pro.numeroFinca -- se obtiene el id de la propiedad usando el numero de finca
	WHERE tup.TipoAsociacion = 'Agregar'

	--finalizamos las relaciones que se indican como Eliminar
	UPDATE udp
	SET    udp.fechaFin = @inFechaOperacion
	FROM  [dbo].[UsuarioDePropiedad] AS udp -- contine las relaciones de usuarios y propiedades
	INNER JOIN [dbo].[Propiedad] AS pro ON udp.idPropiedad = pro.id --asi no eliminamos las propiedades no registradas
	INNER JOIN @temp_UsuariosyPropiedades AS tup ON tup.NumeroFinca = pro.numeroFinca -- obtenemos el numero de finca en relacion 1 a 1
	WHERE  tup.TipoAsociacion = 'Eliminar'
	AND udp.fechaInicio IS NOT NULL

	EXEC sp_xml_removedocument @hdoc

	SET NOCOUNT OFF;
END