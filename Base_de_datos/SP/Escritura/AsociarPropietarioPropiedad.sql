/*
    Procedimiento que asocia a una persona con una propiedad
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Inserción realizada correctamente

-- Error --
    50000: Ocurrió un error desconocido
    50001: Ocurrió un error desconocido en una transacción
    50002: Credenciales incorrectas
	50003: Numero de finca invalido
    50009: No existe la persona/Usuario indicado
    50014: Ya existe la asociación
*/

ALTER PROCEDURE [dbo].[AsociarPropietarioPropiedad]
    -- Se definen las variables de entrada
    @inValorDocumentoId VARCHAR(32),
    @inNumeroFinca INT,

    -- Para determinar quién está haciendo la transacción
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @idUser INT;            -- Para guardar el ID del usuario
	DECLARE @idPersona INT;         -- Para guardar el ID de la persona
    DECLARE @idPropiedad INT;       -- Para guardar el ID de la propiedad
	DECLARE @fechaActual DATETIME;
	DECLARE @LogDescription VARCHAR(512);

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY
        -- Empiezan las validaciones

        -- 1. ¿Existe el usuario como administrador?
        
        IF EXISTS( SELECT 1 
				   FROM [dbo].[Usuario] U
				   INNER JOIN [dbo].[TipoUsuario] T
				   ON U.idTipoUsuario = T.id
				   WHERE U.nombreDeUsuario = @inUsername
				   AND T.nombre = 'Administrador'
				 )
        BEGIN
            SET @idUser = ( SELECT U.id 
							FROM [dbo].[Usuario] U
							INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
							WHERE U.nombreDeUsuario = @inUsername
							AND T.nombre = 'Administrador'
						  );
        END
        ELSE
        BEGIN
            SET @outResultCode = 50002; -- Credenciales incorrectas
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 2. ¿Existe la persona?
        
        IF EXISTS(
            SELECT 1 FROM [dbo].[Persona] P
            WHERE P.valorDocumentoId = @inValorDocumentoId
            )
        BEGIN
            SET @idPersona = ( SELECT P.id 
							   FROM [dbo].[Persona] P
							   WHERE P.valorDocumentoId = @inValorDocumentoId
							 );
        END
        ELSE
        BEGIN
            SET @outResultCode = 50009; -- No existe la persona indicada
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 3. ¿Existe la propiedad?

        IF EXISTS( SELECT 1 
				   FROM [dbo].[Propiedad] P
				   WHERE P.numeroFinca = @inNumeroFinca
				 )
        BEGIN
            SET @idPropiedad = ( SELECT P.id 
								 FROM [dbo].[Propiedad] P
								 WHERE P.numeroFinca = @inNumeroFinca
							   );
        END
        ELSE
        BEGIN
            SET @outResultCode = 50003; -- No existe la propiedad
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 4. ¿Ya existe la asociación?
        IF EXISTS( SELECT 1 
				   FROM [dbo].[PropietarioDePropiedad] PdP
				   WHERE PdP.idPersona = @idPersona
				   AND PdP.idPropiedad = @idPropiedad
				   AND fechaFin IS NULL    -- NULL = Sigue activa
				 )
        BEGIN
            SET @outResultCode = 50014; -- Ya existe la asociacion
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END

        -- Si llega acá, ya pasaron las validaciones
        -- Se crea el mensaje para la bitácora
        
        SET @fechaActual = GETDATE();
		
        
        SET @LogDescription = 'Se inserta en la tabla [dbo].[PropietarioDePropiedad]: '
            + '{idPropiedad = "' + CONVERT(VARCHAR, @idPropiedad) + '", '
            + 'idPersona = "' + CONVERT(VARCHAR, @idPersona) + '", '
            + 'fechaInicio = "' + CONVERT(VARCHAR, @fechaActual, 21) + '"'
            + '}';

        BEGIN TRANSACTION tAsociarPropietarioPropiedad
            -- Empieza la transacción

            -- Se inserta la asociación
            INSERT INTO [dbo].[PropietarioDePropiedad] (
                [idPersona],
                [idPropiedad],
                [fechaInicio]
            )
            VALUES (
                @idPersona,
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

        COMMIT TRANSACTION tAsociarPropietarioPropiedad;

    END TRY
    BEGIN CATCH
        -- Si llega acá, hubo algún error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- ¿Fue dentro de una transacción?
        BEGIN
            ROLLBACK TRANSACTION tAsociarPropietarioPropiedad;
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