/*
    Procedimiento que asocia a un Usuario con una propiedad
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Inserción realizada correctamente

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
	50009: No existe la persona/Usuario indicado
	50010: Ya hay una Persona con ese documento identidad
*/

ALTER PROCEDURE [dbo].[AsociarUsuarioPropiedad]
    -- Se definen las variables de entrada
    @inDbUsername VARCHAR(32),
	@inNumeroFinca INT,

    -- Para determinar qui�n est� haciendo la transacci�n
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @Numero AS INT = 0;
	DECLARE @idPropiedad INT;       -- Para guardar el ID de la propiedad

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY
        -- Empiezan las validaciones

        -- 1. ¿Existe el usuario como administrador?
        DECLARE @idUser INT;            -- Para guardar el ID del usuario
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

        --2. nombre de Usuario a asociar existe?
        
		--obtenemos el id del Usuario
		--de no existir @Numero = 0
		SELECT @Numero = u.id
		FROM [dbo].[Usuario] u
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[Usuario] u
					 WHERE u.nombreDeUsuario = @inDbUsername);

		IF @Numero = 0
        BEGIN
            -- Nombre de Usuario a borrar no existe
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;


        -- 3. ¿Existe la propiedad?
        
        IF EXISTS(
            SELECT 1 FROM [dbo].[Propiedad] P
            WHERE P.numeroFinca = @inNumeroFinca
            )
        BEGIN
			-- si existe
            SET @idPropiedad = (
                SELECT P.id FROM [dbo].[Propiedad] P
                WHERE P.numeroFinca = @inNumeroFinca
                );
        END
        ELSE
        BEGIN
			--no exuiste
            SET @outResultCode = 50004; -- No existe la propiedad
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;


		-- 4. ¿Existe la asociacion?
        
        IF EXISTS(
            SELECT 1 FROM [dbo].[UsuarioDePropiedad] udp
			INNER JOIN Usuario u ON u.id = udp.idUsuario
			INNER JOIN Propiedad p ON p.id = udp.idPropiedad
            WHERE CAST(u.nombreDeUsuario AS BINARY) = CAST(@inDbUsername AS BINARY)
			AND p.numeroFinca = @inDbUsername
			AND udp.fechaFin = NULL
            )
        BEGIN
			--ya existe
            SET @outResultCode = 50002; -- No existe la propiedad
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, ya pasaron las validaciones
        -- Se crea el mensaje para la bitácora
        DECLARE @fechaActual DATETIME;
        SET @fechaActual = GETDATE();

        DECLARE @LogDescription VARCHAR(512);
        SET @LogDescription = 'Se inserta en la tabla [dbo].[UsuarioDePropiedad]: '
            + '{idUsuario = "' + CONVERT(VARCHAR, @Numero) + '", '
            + 'idPropiedad = "' + CONVERT(VARCHAR, @idPropiedad) + '", '
            + 'fechaInicio = "' + CONVERT(VARCHAR, @fechaActual, 21) + '"'
            + '}';

        BEGIN TRANSACTION tAsociarUsuarioPropiedad
            -- Empieza la transacción

            -- Se inserta la asociación
            INSERT INTO [dbo].[UsuarioDePropiedad] (
                [idUsuario],
                [idPropiedad],
                [fechaInicio]
            )
            VALUES (
                @Numero,
                @idPropiedad,
                @fechaActual
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
                @fechaActual,
                @idUser,
                @inUserIp
            );

        COMMIT TRANSACTION tAsociarUsuarioPropiedad;

    END TRY
    BEGIN CATCH
        -- Si llega acá, hubo algún error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- ¿Fue dentro de una transacción?
        BEGIN
            ROLLBACK TRANSACTION tAsociarUsuarioPropiedad;
            SET @outResultCode = 50001; -- Error desconocido dentro de la transacción
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