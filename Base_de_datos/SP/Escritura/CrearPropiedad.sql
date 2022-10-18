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
    50008: Valor de medidor inválido
    50009: Ya existe una propiedad con ese medidor
*/

ALTER PROCEDURE [dbo].[CrearPropiedad]
	-- Se definen las variables de entrada
    @inNombreTipoUsoPropiedad VARCHAR(32),
    @inNombreTipoZonaPropiedad VARCHAR(32),
    @inNumeroFinca INT,
    @inArea INT,
    @inValorFiscal BIGINT,
    @inNumeroMedidor INT,

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

        -- 2. �N�mero de finca v�lido?
        IF @inNumeroFinca < 0
        BEGIN
            -- N�mero de finca inv�lido (negativo)
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;
        
        -- 3. �Valor de �rea v�lido?
        IF @inArea < 0
        BEGIN
            -- Valor de �rea inv�lido (negativo)
            SET @outResultCode = 50004;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 4. �Existe el tipo de zona?
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

        -- 5. �Existe el tipo de uso de la propiedad?
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

        -- 6. �Ya existe el n�mero de finca?
        IF EXISTS(
            SELECT 1 FROM [dbo].[Propiedad] P
            WHERE P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- Ya existe el n�mero de finca
            SET @outResultCode = 50007;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 7. ¿Número de medidor válido?
        IF @inArea < 1
        BEGIN
            -- Valor de medidor inválido
            SET @outResultCode = 50008;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- 8. ¿Ya existe el número de medidor?
        IF EXISTS(
            SELECT 1 FROM [dbo].[AguaDePropiedad] AdP
            WHERE AdP.[numeroMedidor] = @inNumeroMedidor
            )
        BEGIN
            -- Ya existe el número de medidor
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        DECLARE @LogDescription VARCHAR(512);
        SET @LogDescription = 'Se inserta en la tabla [dbo].[Propiedad]: '
            + '{idTipoZona = "' + CONVERT(VARCHAR, @idTipoZona) + '", '
            + 'tipoUsoPropiedad = "' + CONVERT(VARCHAR, @idTipoUso) + '", '
            + 'numeroFinca = "' + CONVERT(VARCHAR, @inNumeroFinca) + '", '
            + 'valorFiscal = "' + CONVERT(VARCHAR, @inValorFiscal) + '", '
            + 'area = "' + CONVERT(VARCHAR, @inArea) + '"'
            + '} y el medidor {nnumeroMedidor = "' + CONVERT(VARCHAR, @inNumeroMedidor) + '"}';

        BEGIN TRANSACTION tCrearPropiedad
            -- Empieza la transacci�n

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

            -- Se inserta el medidor
            INSERT INTO [dbo].[AguaDePropiedad] ([id], [numeroMedidor], [consumoAcumulado])
            SELECT CCdP.[id], @inNumeroMedidor, 0
            FROM [dbo].[ConceptoCobroDePropiedad] CCdP
            INNER JOIN [dbo].[Propiedad] P
            ON CCdP.idPropiedad = P.id
            WHERE CCdP.idConceptoCobro = 1          -- 1 = agua
                AND P.numeroFinca = @inNumeroFinca;

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
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tCrearPropiedad;
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