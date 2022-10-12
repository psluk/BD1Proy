/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Inserción realizada correctamente

-- Error --
    50000: Ocurrió un error desconocido
    50001: Ocurrió un error desconocido en una transacción
    50002: Credenciales incorrectas
    50003: Número de finca inválido
    50004: Valor de área inválido
    50005: No existe el tipo de zona
    50006: No existe el tipo de uso de la propiedad
    50007: Ya hay una propiedad con ese número de finca
*/

ALTER PROCEDURE [dbo].[CrearPropiedad]
	-- Se definen las variables de entrada
    @inNombreTipoUsoPropiedad VARCHAR(32),
    @inNombreTipoZonaPropiedad VARCHAR(32),
    @inNumeroFinca INT,
    @inArea INT,
    @inValorFiscal BIGINT,
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
        IF @inNumeroFinca < 0
        BEGIN
            -- Número de finca inválido (negativo)
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;
        
        -- 3. ¿Valor de área válido?
        IF @inArea < 0
        BEGIN
            -- Valor de área inválido (negativo)
            SET @outResultCode = 50004;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 4. ¿Existe el tipo de zona?
        DECLARE @idTipoZona INT;            -- Para el ID del tipo de zona
        IF EXISTS(
            SELECT 1 FROM [dbo].[TipoZona] TZ
            WHERE TZ.nombre = @inNombreTipoZonaPropiedad
            )
        BEGIN
            SET @idTipoZona = (
                SELECT TZ.id FROM [dbo].[TipoZona] TZ
                WHERE TZ.nombre = @inNombreTipoZonaPropiedad
            );
        END
        ELSE
        BEGIN
            -- Nombre de tipo de zona inexistente
            SET @outResultCode = 50005;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 5. ¿Existe el tipo de uso de la propiedad?
        DECLARE @idTipoUso INT;            -- Para el ID del tipo de zona
        IF EXISTS(
            SELECT 1 FROM [dbo].[TipoUsoPropiedad] TU
            WHERE TU.nombre = @inNombreTipoUsoPropiedad
            )
        BEGIN
            SET @idTipoUso = (
                SELECT TU.id FROM [dbo].[TipoUsoPropiedad] TU
                WHERE TU.nombre = @inNombreTipoUsoPropiedad
            );
        END
        ELSE
        BEGIN
            -- Nombre de tipo de uso de propiedad inexistente
            SET @outResultCode = 50006;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 6. ¿Ya existe el el número de finca?
        IF EXISTS(
            SELECT 1 FROM [dbo].[Propiedad] P
            WHERE P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- Ya existe el número de finca
            SET @outResultCode = 50007;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, ya pasaron las validaciones
        -- Se crea el mensaje para la bitácora
        DECLARE @LogDescription VARCHAR(512);
        SET @LogDescription = 'Se inserta en la tabla [dbo].[Propiedad]: '
            + '{idTipoZona = "' + CONVERT(VARCHAR, @idTipoZona) + '", '
            + 'tipoUsoPropiedad = "' + CONVERT(VARCHAR, @idTipoUso) + '", '
            + 'numeroFinca = "' + CONVERT(VARCHAR, @inNumeroFinca) + '", '
            + 'valorFiscal = "' + CONVERT(VARCHAR, @inValorFiscal) + '", '
            + 'area = "' + CONVERT(VARCHAR, @inArea) + '"'
            + '}';

        BEGIN TRANSACTION tCrearPropiedad
            -- Empieza la transacción

            -- Se inserta la propiedad
            INSERT INTO [dbo].[Propiedad] (
                [idTipoUsoPropiedad],
                [idTipoZona],
                [numeroFinca],
                [area],
                [valorFiscal],
                [fechaRegistro]
            )
            VALUES (
                @idTipoUso,
                @idTipoZona,
                @inNumeroFinca,
                @inArea,
                @inValorFiscal,
                GETDATE()
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

        COMMIT TRANSACTION tCrearPropiedad;

    END TRY
    BEGIN CATCH
        -- Si llega acá, hubo algún error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- ¿Fue dentro de una transacción?
        BEGIN
            ROLLBACK TRANSACTION tCrearPropiedad;
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