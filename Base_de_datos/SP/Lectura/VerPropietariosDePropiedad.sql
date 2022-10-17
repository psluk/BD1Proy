/*
    Procedimiento que retorna los dueños de una propiedad
    (para un número de finca dado)
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Correcto

-- Error --
    50000: Ocurrió un error desconocido
    50001: Credenciales inválidas
    50002: La propiedad no existe
*/

ALTER PROCEDURE [dbo].[VerPropietariosDePropiedad]
    -- Se definen las variables de entrada
    @inNumeroFinca VARCHAR(32),

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS(
                SELECT 1 FROM [dbo].[Usuario] U
                INNER JOIN [dbo].[TipoUsuario] T
                ON U.idTipoUsuario = T.id
                WHERE U.nombreDeUsuario = @inUsername
                    AND T.nombre = 'Administrador'
                )
        BEGIN
            -- Si llega acá, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inválidas
            SELECT NULL AS 'Nombre', NULL AS 'ID', NULL AS 'Inicio';
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
            -- Sí existe
            SET @idPropiedad = (
                SELECT P.id FROM [dbo].[Propiedad] P
                WHERE P.numeroFinca = @inNumeroFinca
                );
        END
        ELSE
        BEGIN 
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Propiedad inexistente
            SELECT NULL AS 'Nombre', NULL AS 'ID', NULL AS 'Inicio';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, se buscan los propietarios
        SELECT P.nombre AS 'Nombre', P.valorDocumentoId AS 'ID', PdP.fechaInicio AS 'Inicio'
        FROM [dbo].[Persona] P
        INNER JOIN [dbo].[PropietarioDePropiedad] PdP
        ON PdP.idPersona = P.id
        WHERE PdP.idPropiedad = @idPropiedad
            AND PdP.fechaFin IS NULL; -- NULL = sigue activa la relación

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurrió un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Nombre', NULL AS 'ID', NULL AS 'Inicio';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;