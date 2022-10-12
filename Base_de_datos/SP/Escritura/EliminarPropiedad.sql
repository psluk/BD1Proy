/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Eliminación realizada correctamente

-- Error --
    50000: Ocurrió un error desconocido
    50001: Ocurrió un error desconocido en una transacción
    50002: Credenciales incorrectas
    50003: No existe el número de finca
*/

ALTER PROCEDURE [dbo].[EliminarPropiedad]
    -- Se definen las variables de entrada
    @inNumeroFinca INT,
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)

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

        -- 2. ¿Número de finca válido?
        DECLARE @idPropiedad INT;       -- Donde se guardará el ID de la propiedad
        IF EXISTS (
            SELECT 1 FROM [dbo].[Propiedad] P
            WHERE P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- Sí existe
            SET @idPropiedad = (
                SELECT P.id FROM [dbo].[Propiedad] P
                WHERE P.numeroFinca = @inNumeroFinca
            )
        END
        ELSE
        BEGIN
            -- Número de finca inexistente
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, ya pasaron las validaciones
        -- Se crea el mensaje para la bitácora
        DECLARE @LogDescription AS VARCHAR(512);
        SET @LogDescription = 'Se elimina de la tabla [dbo].[Propiedad]: '
            + '{id = "' + CONVERT(VARCHAR, @idPropiedad) + '", '
            + 'numeroFinca = "' + CONVERT(VARCHAR, @inNumeroFinca) + '"'
            + '}';

        BEGIN TRANSACTION tBorrarPropiedad
            -- Empieza la transacción

            -- Se elimina
            DELETE FROM [dbo].[Propiedad]
            WHERE [id] = @idPropiedad;

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

        COMMIT TRANSACTION tBorrarPropiedad;

    END TRY
    BEGIN CATCH
        -- Si llega acá, hubo algún error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- ¿Fue dentro de una transacción?
        BEGIN
            ROLLBACK TRANSACTION tBorrarPropiedad;
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