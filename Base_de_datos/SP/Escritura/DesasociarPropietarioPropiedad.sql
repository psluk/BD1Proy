/*
    Procedimiento que desasocia una persona y una propiedad
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Inserci�n realizada correctamente

-- Error --
    50000: Ocurri� un error desconocido
    50001: Ocurri� un error desconocido en una transacci�n
    50002: Credenciales incorrectas
    50003: No existe la asociaci�n
*/

ALTER PROCEDURE [dbo].[DesasociarPropietarioPropiedad]
    -- Se definen las variables de entrada
    @inValorDocumentoId VARCHAR(32),
    @inNumeroFinca INT,

    -- Para determinar qui�n est� haciendo la transacci�n
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY
        -- Empiezan las validaciones

        -- 1. �Existe el usuario como administrador?
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

        -- 2. �Existe la asociaci�n?
        DECLARE @idPropietarioPropiedad INT;    -- Para guardar el ID de la asociaci�n
        IF EXISTS(
            SELECT 1 FROM [dbo].[PropietarioDePropiedad] PdP
            INNER JOIN [dbo].[Propiedad] Pro ON Pro.id = PdP.idPropiedad
            INNER JOIN [dbo].[Persona] Per ON Per.id = PdP.idPersona
            WHERE PdP.fechaFin IS NULL  -- La relaci�n debe estar activa (fechaFin = NULL)
            )
        BEGIN
            SET @idPropietarioPropiedad = (
                SELECT PdP.id FROM [dbo].[PropietarioDePropiedad] PdP
                INNER JOIN [dbo].[Propiedad] Pro ON Pro.id = PdP.idPropiedad
                INNER JOIN [dbo].[Persona] Per ON Per.id = PdP.idPersona
                WHERE PdP.fechaFin IS NULL
                );
        END
        ELSE
        BEGIN
            SET @outResultCode = 50003; -- No existe
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        DECLARE @fechaActual DATETIME;
        SET @fechaActual = GETDATE();

        DECLARE @LogDescription VARCHAR(512);
        SET @LogDescription = 'Se modifica la tabla [dbo].[PropietarioDePropiedad]: '
            + '{id = "' + CONVERT(VARCHAR, @idPropietarioPropiedad) + '", '
            + 'fechaFin = "' + CONVERT(VARCHAR, @fechaActual, 21) + '"'
            + '}';

        BEGIN TRANSACTION tAsociarPropietarioPropiedad
            -- Empieza la transacci�n

            -- Se actualiza
            UPDATE [dbo].[PropietarioDePropiedad]
            SET [fechaFin] = @fechaActual
            WHERE [id] = @idPropietarioPropiedad;

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
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tAsociarPropietarioPropiedad;
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