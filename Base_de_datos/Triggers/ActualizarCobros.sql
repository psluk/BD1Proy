ALTER TRIGGER [dbo].[CambiarConceptosCobro]
ON [dbo].[Propiedad]
AFTER UPDATE
AS
BEGIN
    -- Cambios posibles:
    -- 1. Pasa de zona de uso no agrícola a agrícola (se quita CC #3, de basura)
    -- 2. Al revés (se agrega CC #3, de basura)
    -- 3. Pasa de zona comercial o residencial (5 o 1) a otra
    --  (se quita CC #7, de mantenimiento de parques)
    -- 4. Al revés (se agrega CC #7)

    IF (UPDATE (idTipoZona) OR UPDATE (idTipoUsoPropiedad))
    BEGIN
        -- Pasó de uso agrícola (5) a uso no agrícola
        -- Se borra 3
        UPDATE CCdP
        SET fechaFin = GETDATE()
        FROM [dbo].[ConceptoCobroDePropiedad] CCdP
        INNER JOIN deleted D
        ON CCdP.[idPropiedad] = D.[id]
        INNER JOIN inserted I
        ON CCdP.[idPropiedad] = I.[id]
        WHERE D.idTipoUsoPropiedad != 5
            AND I.idTipoUsoPropiedad = 5
            AND CCdP.[idConceptoCobro] = 3;

        -- Pasó de uso no agrícola a agrícola (5)
        INSERT INTO [ConceptoCobroDePropiedad] (
            [idConceptoCobro], [idPropiedad], [fechaInicio]
            )
        SELECT 3, d.id, GETDATE()
        FROM deleted D
        INNER JOIN inserted I
        ON D.[id] = I.[id]
        WHERE D.idTipoUsoPropiedad = 5
            AND I.idTipoUsoPropiedad != 5;

        -- Pasa de comercial o residencial (5 o 1) a otra
        UPDATE CCdP
        SET fechaFin = GETDATE()
        FROM [dbo].[ConceptoCobroDePropiedad] CCdP
        INNER JOIN deleted D
        ON CCdP.[idPropiedad] = D.[id]
        INNER JOIN inserted I
        ON CCdP.[idPropiedad] = I.[id]
        WHERE (D.idTipoZona = 5 OR D.idTipoZona = 1)
            AND (I.idTipoZona != 1 AND I.idTipoZona != 5)
            AND CCdP.[idConceptoCobro] = 7;

        -- Pasa a ser comercial o residencial
        INSERT INTO [ConceptoCobroDePropiedad] (
            [idConceptoCobro], [idPropiedad], [fechaInicio]
            )
        SELECT 7, d.id, GETDATE()
        FROM deleted D
        INNER JOIN inserted I
        ON D.[id] = I.[id]
        WHERE (D.idTipoZona != 1 AND D.idTipoZona != 5)
            AND (I.idTipoZona = 5 OR I.idTipoZona = 1);
    END;
END;