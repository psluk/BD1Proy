--SP (Des)asociacion Usuarios Propiedades
-- segun informacion del nodo recibido



ALTER PROCEDURE [dbo].[AsociacionUsuarioPropiedadXml]
						@hdoc INT,
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
	
	INSERT INTO @temp_UsuariosyPropiedades (
				ValorDocumentoIdentidad, 
				NumeroFinca, 
				TipoAsociacion)
	SELECT ValorDocumentoIdentidad, 
		   NumeroFinca, 
		   TipoAsociacion
	FROM OPENXML(@hdoc, 'Operacion/PropiedadesyUsuarios/UsuarioPropiedad', 1)
	WITH 
	(
		ValorDocumentoIdentidad BIGINT,
		NumeroFinca INT,
		TipoAsociacion varchar(32)
	);
	
	UPDATE @temp_UsuariosyPropiedades
	SET FechaOperacion = @inFechaOperacion;

	BEGIN TRANSACTION

	--inicializamos las relaciones que se indican como Agregar
	INSERT INTO [dbo].[UsuarioDePropiedad](
				[idUsuario], 
				[idPropiedad], 
				[fechaInicio])
	SELECT u.id, 
		   pro.id, 
		   tup.FechaOperacion
	FROM @temp_UsuariosyPropiedades AS tup
	INNER JOIN [dbo].[Persona] AS per ON tup.ValorDocumentoIdentidad = per.valorDocumentoId --se obtiene el id del documento identidad
	INNER JOIN [dbo].[Usuario] AS u ON u.idPersona = per.id -- se obtiene el id del usuario usando el id de la persona
	INNER JOIN [dbo].[Propiedad] AS pro ON tup.NumeroFinca = pro.numeroFinca -- se obtiene el id de la propiedad usando el numero de finca
	WHERE tup.TipoAsociacion = 'Agregar';

	COMMIT TRANSACTION

	--insercion en tabla de control para poder verificar el orden de insercion de las asociaciones y verificar si existen desasociaciones correctas
	INSERT INTO [dbo].[socorro] ([idUsuario], [idPersona], [ValorDocumentoIdentidad], [idPropiedad], [NumeroFinca], [TipoAsociacion], [FechaOperacion])
	SELECT u.id, per.id, per.valorDocumentoId, pro.id, pro.numeroFinca, tup.TipoAsociacion, @inFechaOperacion
	FROM @temp_UsuariosyPropiedades AS tup
	INNER JOIN [dbo].[Persona] AS per ON tup.ValorDocumentoIdentidad = per.valorDocumentoId --se obtiene el id del documento identidad
	INNER JOIN [dbo].[Usuario] AS u ON u.idPersona = per.id -- se obtiene el id del usuario usando el id de la persona
	INNER JOIN [dbo].[Propiedad] AS pro ON tup.NumeroFinca = pro.numeroFinca -- se obtiene el id de la propiedad usando el numero de finca
	INNER JOIN  [dbo].[UsuarioDePropiedad] AS udp ON udp.idUsuario = u.id -- contine las relaciones de usuarios y propiedades
	WHERE   udp.idPropiedad = pro.id




	--finalizamos las relaciones que se indican como Eliminar
	UPDATE udp
	SET    udp.fechaFin = @inFechaOperacion
	FROM @temp_UsuariosyPropiedades AS tup
	INNER JOIN [dbo].[Persona] AS per ON tup.ValorDocumentoIdentidad = per.valorDocumentoId --se obtiene el id de la persona usando documento identidad
	INNER JOIN [dbo].[Usuario] AS u ON u.idPersona = per.id -- se obtiene el id del usuario usando el id de la persona
	INNER JOIN [dbo].[Propiedad] AS pro ON tup.NumeroFinca = pro.numeroFinca -- se obtiene el id de la propiedad usando el numero de finca
	INNER JOIN  [dbo].[UsuarioDePropiedad] AS udp ON udp.idUsuario = u.id -- vinculamos la tabla temporal con la de memoria 
	WHERE   udp.idPropiedad = pro.id -- nos sercioramos que sea en la misma propiedad
	AND tup.TipoAsociacion = 'Eliminar'
	AND udp.fechaInicio IS NOT NULL
	AND udp.fechaFin IS NULL
	SET NOCOUNT OFF;
END



	