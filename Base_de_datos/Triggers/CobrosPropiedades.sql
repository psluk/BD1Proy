ALTER TRIGGER [dbo].[AsignarConceptosCobro]
ON [dbo].[Propiedad]
AFTER INSERT
AS
BEGIN

    -- Se agregan los siguientes conceptos de cobro para todas las propiedades
    -- 1: Consumo de agua
    -- 2: Impuesto a la propiedad
    -- 4: Patente comercial
    -- 5: Reconexión
    -- 6: Intereses moratorios
    INSERT INTO [ConceptoCobroDePropiedad] (
        [idConceptoCobro], [idPropiedad], [fechaInicio]
        )
    SELECT CC.[id], i.[id], i.[fechaRegistro]
    FROM inserted i, [dbo].[ConceptoCobro] CC
    WHERE CC.id = 1 OR CC.id = 2 OR CC.id = 4 OR CC.id = 5 OR CC.id = 6;

    -- Se agrega la recolección de basura (3) para zonas de uso no agrícola:
    INSERT INTO [ConceptoCobroDePropiedad] (
        [idConceptoCobro], [idPropiedad], [fechaInicio]
        )
    SELECT CC.[id], i.[id], i.[fechaRegistro]
    FROM inserted i, [dbo].[ConceptoCobro] CC
    WHERE CC.id = 3
        AND i.idTipoUsoPropiedad != 5;  -- 5 = zona agrícola

    -- Se agrega el mantenimiento de parques (7) para zonas comerciales
    -- e industriales:
    INSERT INTO [ConceptoCobroDePropiedad] (
        [idConceptoCobro], [idPropiedad], [fechaInicio]
        )
    SELECT CC.[id], i.[id], i.[fechaRegistro]
    FROM inserted i, [dbo].[ConceptoCobro] CC
    WHERE CC.id = 7
        AND (i.idTipoZona = 1 OR i.idTipoZona = 5);
        -- 1 = residencial, 5 = comercial
END;