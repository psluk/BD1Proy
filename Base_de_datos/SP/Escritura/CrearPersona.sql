/*
    Procedimiento que crea una propiedad con unos par�metros dados
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Inserci�n realizada correctamente

-- Error --
    50000: Ocurri� un error desconocido
    50001: Ocurri� un error desconocido en una transacci�n
    50002: Credenciales incorrectas
    50003: N�mero de finca inv�lido
    50004: Valor de �rea inv�lido
    50005: No existe el tipo de zona
    50006: No existe el tipo de uso de la propiedad
    50007: Ya hay una propiedad con ese n�mero de finca
	50008: Ya hay un Usuario con ese nombre
	50009: No existe el la persona asociada a ese numero de identidad
	50010: Ya hay una Persona con ese documento identidad
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

    SET NOCOUNT ON;         -- Para evitar interferencias
    
    BEGIN TRY
        -- Empiezan las validaciones
        -- 1. �Existe el usuario como administrador?
        
        IF EXISTS(
            SELECT 1 FROM [dbo].[Usuario] U
            INNER JOIN [dbo].[TipoUsuario] T
            ON U.idTipoUsuario = T.id
            WHERE U.nombreDeUsuario = @inUsername
                AND T.nombre = 'Administrador'
            )
        BEGIN
            SET @idUser = (SELECT U.id FROM [dbo].[Usuario] U
                INNER JOIN [dbo].[TipoUsuario] T
                ON U.idTipoUsuario = T.id
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
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[Persona] 
					 WHERE p.valorDocumentoId = @inNuevoValorDocumentoId);

		IF @Numero != 0
        BEGIN
            -- N�mero de DocumentoIdentidad ya existe
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		--3. existe el tipodocumento?

		SELECT @idTipoDocumentoId = td.id
		FROM TipoDocumentoId td
		WHERE EXISTS(SELECT 1 
					 FROM TipoDocumentoId
					 WHERE TipoDocumentoId.nombre = @inNuevoTipoDocumentoId) AND td.nombre = 'Cedula CR';

		IF @idTipoDocumentoId = -1
        BEGIN
            -- el tipo documento no existe
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;
		
        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        DECLARE @LogDescription VARCHAR(512);
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