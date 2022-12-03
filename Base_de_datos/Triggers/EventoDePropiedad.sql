/*
    Trigger para guardar los eventos de la tabla de propiedades
*/

ALTER TRIGGER [dbo].[EventoDePropiedad]
ON [dbo].[Propiedad]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    BEGIN TRY 
        DECLARE @cambios TABLE (
            id INT,
            jsonAntes VARCHAR(512) NULL,
            jsonDespues VARCHAR(512) NULL
        );

        INSERT INTO @cambios
        (
            [id],
            [jsonAntes],
            [jsonDespues]
        )
        -- Propiedad nueva
        SELECT  I.id,
                NULL,
               (SELECT  I2.[idTipoUsoPropiedad] AS 'idTipoUsoPropiedad', 
    			        I2.[idTipoZona] AS 'idTipoZona', 
				        I2.[numeroFinca] AS 'numeroFinca', 
				        I2.[area] AS 'area', 
				        I2.[valorFiscal] AS 'valorFiscal', 
				        I2.[fechaRegistro], 
				        I2.[consumoAcumulado], 
				        I2.[acumuladoUltimaFactura]
				FROM inserted I2
                WHERE I.[id] = I2.[id]
                FOR JSON AUTO)
        FROM    inserted I
        WHERE   NOT EXISTS( SELECT  1
                            FROM    deleted D
                            WHERE   D.[id] = I.[id])
        -- Propiedad borrada
        UNION
        SELECT  D.id,
               (SELECT  D2.[idTipoUsoPropiedad] AS 'idTipoUsoPropiedad', 
				        D2.[idTipoZona] AS 'idTipoZona', 
				        D2.[numeroFinca] AS 'numeroFinca', 
				        D2.[area] AS 'area', 
				        D2.[valorFiscal] AS 'valorFiscal', 
				        D2.[fechaRegistro], 
				        D2.[consumoAcumulado], 
				        D2.[acumuladoUltimaFactura]
				FROM deleted D2
                WHERE D.[id] = D2.[id]
                FOR JSON AUTO),
                NULL
        FROM    deleted D
        WHERE   NOT EXISTS( SELECT  1
                            FROM    inserted I
                            WHERE   D.[id] = I.[id])
        -- Propiedad actualizada
        UNION
        SELECT  D.id,
               (SELECT  D2.[idTipoUsoPropiedad] AS 'idTipoUsoPropiedad', 
				        D2.[idTipoZona] AS 'idTipoZona', 
				        D2.[numeroFinca] AS 'numeroFinca', 
				        D2.[area] AS 'area', 
				        D2.[valorFiscal] AS 'valorFiscal', 
				        D2.[fechaRegistro], 
				        D2.[consumoAcumulado], 
				        D2.[acumuladoUltimaFactura]
				FROM deleted D2
                WHERE D.[id] = D2.[id]
                FOR JSON AUTO),
               (SELECT  I2.[idTipoUsoPropiedad] AS 'idTipoUsoPropiedad', 
				        I2.[idTipoZona] AS 'idTipoZona', 
				        I2.[numeroFinca] AS 'numeroFinca', 
				        I2.[area] AS 'area', 
				        I2.[valorFiscal] AS 'valorFiscal', 
				        I2.[fechaRegistro], 
				        I2.[consumoAcumulado], 
				        I2.[acumuladoUltimaFactura]
				FROM inserted I2
                WHERE I.[id] = I2.[id]
                FOR JSON AUTO)
        FROM    inserted I
        INNER JOIN deleted D
            ON  I.[id] = D.[id];
                
		-- Se inserta el cambio en la bit�cora
		INSERT INTO EventLog(
            [idEntityType], 
			[entityId], 
			[jsonAntes], 
			[jsonDespues], 
			[insertedAt], 
			[insertedByUser], 
			[insertedInIp]
        )
		SELECT  1, 
				C.[id], 
				C.[jsonAntes],
				C.[jsonDespues],
				GETDATE(),
				NULL,
				NULL
		FROM    @cambios C;

    END TRY
    BEGIN CATCH
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
END;