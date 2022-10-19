ALTER PROCEDURE [dbo].[VerTipoDeUsuario]
    @inNombreUsuario VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @output INT = 0;
    IF EXISTS(SELECT 1
        FROM [dbo].[Usuario] U
        INNER JOIN [dbo].[TipoUsuario] TU
        ON U.[idTipoUsuario] = TU.[id]
        WHERE u.[nombreDeUsuario] = @inNombreUsuario)
    BEGIN
        SET @output = 1;
    END;

    SELECT @output AS "resultCode";
    SET NOCOUNT OFF;
END;