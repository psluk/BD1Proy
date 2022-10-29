/*
    Procedimiento que crea una persona segun los parametros dados
*/

/* Resumen de los codigos de salida de este procedimiento
-- exito --
        0: Insercion realizada correctamente

-- Error --
    50000: Ocurrio un error desconocido
    50001: Ocurrio un error desconocido en una transaccion
    50002: Credenciales incorrectas
	50010: Ya hay una Persona con ese documento identidad
	50012: El tipo documento no existe
*/

ALTER PROCEDURE [dbo].[CrearPersona]
	-- Se definen las variables de entrada
	@inNuevoTipoDocumentoId VARCHAR(32),
	@inNuevoNombre VARCHAR(64),
	@inNuevoValorDocumentoId VARCHAR(32),
	@inNuevoTelefono1 BIGINT,
	@inNuevoTelefono2 BIGINT,
	@inNuevoEmail VARCHAR(128),

    -- Para determinar qui�n est� haciendo la transacci�n
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)
	DECLARE @idUser INT;            -- Para guardar el ID del usuario
	DECLARE @Numero AS BIGINT = 0; -- por defecto, 0 (fallo)
	DECLARE @strTexto AS VARCHAR(32) = ''; -- por defecto (vacio)
	DECLARE @idTipoDocumentoId AS INT = -1; -- por defecto (negativo)
	DECLARE @LogDescription VARCHAR(512);

    SET NOCOUNT ON;         -- Para evitar interferencias
    
    BEGIN TRY
        -- Empiezan las validaciones
        -- 1. �Existe el usuario como administrador?
        
        IF EXISTS( SELECT 1 
				   FROM [dbo].[Usuario] U
				   INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
				   WHERE U.nombreDeUsuario = @inUsername
				   AND T.nombre = 'Administrador'
				 )
        BEGIN
            SET @idUser = ( SELECT U.id 
							FROM [dbo].[Usuario] U
							INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
							WHERE U.nombreDeUsuario = @inUsername
							AND T.nombre = 'Administrador');
        END
        ELSE
        BEGIN
            SET @outResultCode = 50002; -- Credenciales incorrectas
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		--2. ya existe la persona a crear?

        
		--obtenemos el id del docummento identidad asociado
		--de no existir @Numero = 0
		SELECT @Numero = p.id
		FROM [dbo].[Persona] p
		WHERE EXISTS( SELECT 1 
					  FROM [dbo].[Persona] 
					  WHERE p.valorDocumentoId = @inNuevoValorDocumentoId);

		IF @Numero != 0
        BEGIN
            -- Numero de DocumentoIdentidad ya existe
            SET @outResultCode = 50010;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		--3. existe el tipodocumento?

		SELECT @idTipoDocumentoId = td.id
		FROM TipoDocumentoId td
		WHERE EXISTS( SELECT 1 
					  FROM TipoDocumentoId
					  WHERE TipoDocumentoId.nombre = @inNuevoTipoDocumentoId
					) --AND td.nombre = 'Cedula CR';

		IF @idTipoDocumentoId = -1
        BEGIN
            -- el tipo documento no existe
            SET @outResultCode = 50012;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;
		
        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        
        SET @LogDescription = 'Se inserta en la tabla [dbo].[Persona]: '
            + '{ValorDocumentoId = "' + @inNuevoValorDocumentoId + '", '
			+ 'TipoDocumentoId = "' + CAST(@idTipoDocumentoId AS VARCHAR(32)) + '"'
			+ 'Nombre  = "' + @inNuevoNombre + '"'
            + 'Telefono1 = "' + CAST(@inNuevoTelefono1 AS VARCHAR(32)) + '"'
			+ 'Telefono2 = "' + CAST(@inNuevoTelefono2 AS VARCHAR(32)) + '"'
            + 'Email = "' + @inNuevoEmail + '"'
            + '}';

        BEGIN TRANSACTION tCrearPersona
            -- Empieza la transacci�n

            -- Se inserta la propiedad
            INSERT INTO [dbo].[Persona] (
				[idTipoDocumentoId],
				[nombre],
				[valorDocumentoId],
				[telefono1],
				[telefono2],
				[email]
            )
            VALUES (
            @idTipoDocumentoId,
			@inNuevoNombre,
			@inNuevoValorDocumentoId,
			@inNuevoTelefono1,
			@inNuevoTelefono2,
			@inNuevoEmail
            );
			
            -- Se inserta el evento
            INSERT INTO [dbo].[EventLog] (
				[LogDescription],
				[PostTime],
				[PostByUserId],
				[PostInIp]
            )
            VALUES (
                @LogDescription,
                GETDATE(),
                @idUser,
                @inUserIp
            );

        COMMIT TRANSACTION tCrearPersona;

    END TRY
    BEGIN CATCH
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tCrearPersona;
            SET @outResultCode = 50001; -- Error desconocido dentro de la transacci�n
        END;
        
        -- Registra el error
        INSERT INTO [dbo].[Errors]
        VALUES (
            SUSER_NAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

    END CATCH;

    SELECT @outResultCode AS 'resultCode';
    SET NOCOUNT OFF;
END;