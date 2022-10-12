--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado

ALTER PROCEDURE [dbo].[(Des)InsertarUsuariosXml]
						@inxmlData AS XML = '',
						@inFechaOperacion AS DATE = GETDATE
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @temp_Usuarios TABLE
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
		ValorDocumentoIdentidad BIGINT NOT NULL,
		TipoUsuario varchar(32) NOT NULL,
		TipoAsociacion varchar(32) NOT NULL,
		Password varchar(32) NOT NULL,
		Username varchar(32) NOT NULL
	
	);
	DECLARE @hdoc int;
	EXEC sp_xml_preparedocument @hdoc OUTPUT, @inxmlData;
	
	
	INSERT INTO @temp_Usuarios (ValorDocumentoIdentidad, TipoUsuario, TipoAsociacion, Password, Username)
	
	SELECT ValorDocumentoIdentidad, TipoUsuario, TipoAsociacion, Password, Username
	FROM OPENXML(@hdoc, 'Operacion/Usuario/Usuario', 1)
	WITH 
	(
		ValorDocumentoIdentidad BIGINT,
		TipoUsuario varchar(32),
		TipoAsociacion varchar(32),
		Password varchar(32),
		Username varchar(32)
	);

	INSERT INTO [dbo].[Usuario] ([idPersona], [idTipoUsuario], [nombreDeUsuario], [clave])
	SELECT p.id, tpu.id, tu.Username, tu.Password	
	FROM @temp_Usuarios AS tu
	INNER JOIN [dbo].[Persona] p ON tu.ValorDocumentoIdentidad = p.valorDocumentoId --obtenemos el id del documento identidad
	INNER JOIN [dbo].[TipoUsuario] tpu ON tu.TipoUsuario = tpu.nombre --obtenemos el valor del id del tipo Usuario
	WHERE tu.TipoAsociacion = 'Agregar'
	
	--declaramos una nueva tabla para almacenar usuarios existentes indicados para borrado
		DECLARE @temp_BorrarUsuarios TABLE
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
		idUsuario int NOT NULL,
		ValorDocumentoIdentidad BIGINT NOT NULL,
		Password varchar(32) NOT NULL,
		Username varchar(32) NOT NULL
	
	);

	--Sabiendo cuales usuarios si existen, realizamos una union entre los Usuarios y @temp_Usuarios
	--De esta forma juntamos los usuarios existentes y sus ordenes de borrado
	--e ignoramos las ordenes de borrado sin sentido

	INSERT INTO @temp_BorrarUsuarios(idUsuario, ValorDocumentoIdentidad, Password, Username)
	SELECT u.id, tu.ValorDocumentoIdentidad ,u.clave, u.nombreDeUsuario
	FROM @temp_Usuarios AS tu
	INNER JOIN [dbo].[Usuario] u ON tu.Username = u.nombreDeUsuario
	WHERE tu.Password = u.clave
	AND tu.TipoAsociacion = 'Eliminar'


	--realizamos el borrado de la relacion UsuarioPropiedad
	DELETE udp
	FROM [dbo].[UsuarioDePropiedad] AS udp
	INNER JOIN @temp_BorrarUsuarios tbu  ON udp.idUsuario = tbu.idUsuario


	--realizamos el borrado de los usuarios
	DELETE u
	FROM [dbo].[Usuario] AS u
	INNER JOIN @temp_BorrarUsuarios tbu  ON u.id = tbu.idUsuario

	EXEC sp_xml_removedocument @hdoc

	SET NOCOUNT OFF;
END