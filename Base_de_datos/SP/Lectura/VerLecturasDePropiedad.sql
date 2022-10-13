/*
    Procedimiento que retorna las lecturas y los ajustes de una propiedad
    en particular (por n�mero de finca)
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Inserci�n realizada correctamente

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
    50002: La propiedad no existe
*/

ALTER PROCEDURE [dbo].[VerLecturasDePropiedad]
    -- Se definen las variables de entrada
    @inNumeroFinca INT,

    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        -- o est� tratando de procesar las lecturas de una propiedad suya
        IF NOT EXISTS(  -- �Es administrador?
                SELECT 1 FROM [dbo].[Usuario] U
                INNER JOIN [dbo].[TipoUsuario] T
                ON U.idTipoUsuario = T.id
                WHERE U.nombreDeUsuario = @inUsername
                    AND T.nombre = 'Administrador'
                )
            AND NOT EXISTS( -- �Es un no administrador que consulta algo propio?
                SELECT 1 FROM [dbo].[Usuario] U
                INNER JOIN [dbo].[UsuarioDePropiedad] UdP
                ON U.id = UdP.idUsuario
                INNER JOIN [dbo].[Propiedad] P
                ON UdP.idPropiedad = P.id
                WHERE U.nombreDeUsuario = @inUsername
                    AND UdP.fechaFin IS NULL    -- NULL = relaci�n activa
                    AND P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- Si llega ac�, el usuario no puede ver esas lecturas
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT NULL AS 'Fecha',
                NULL AS 'Tipo',
                NULL AS 'Consumo',
                NULL AS 'Acumulado'
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos que exista la propiedad y obtenemos el ID
        DECLARE @idPropiedad AS INT;
        IF EXISTS (
            SELECT 1 FROM [dbo].[Propiedad] P
            WHERE P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- S� existe
            SET @idPropiedad = (
                SELECT id FROM [dbo].[Propiedad] P
                WHERE P.numeroFinca = @inNumeroFinca
                );
        END
        ELSE
        BEGIN 
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Propiedad inexistente
            SELECT NULL AS 'Fecha',
                NULL AS 'Tipo',
                NULL AS 'Consumo',
                NULL AS 'Acumulado'
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, se buscan las lecturas
        SELECT MC.fecha AS 'Fecha',
            TMC.nombre AS 'Tipo',
            MC.consumoMovimiento AS 'Consumo',
            MC.consumoAcumulado AS 'Acumulado'
        FROM [dbo].[MovimientoConsumo] MC
        INNER JOIN [dbo].[TipoMovimientoConsumo] TMC
        ON MC.idTipoMovimiento = TMC.id
        INNER JOIN [dbo].[AguaDePropiedad] AdP
        ON MC.idAguaDePropiedad = AdP.id
        INNER JOIN [dbo].[ConceptoCobroDePropiedad] CCdP
        ON AdP.id = CCdP.id
        WHERE CCdP.idPropiedad = @idPropiedad
        ORDER BY MC.fecha DESC;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Fecha',
                NULL AS 'Tipo',
                NULL AS 'Consumo',
                NULL AS 'Acumulado'
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;