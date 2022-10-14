USE [Proyecto]

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

    -- Se agrega la recolección de basura (3) para zonas no agrícolas:
    INSERT INTO [ConceptoCobroDePropiedad] (
        [idConceptoCobro], [idPropiedad], [fechaInicio]
        )
    SELECT CC.[id], i.[id], i.[fechaRegistro]
    FROM inserted i, [dbo].[ConceptoCobro] CC
    WHERE CC.id = 3
        AND i.idTipoZona != 2;              -- 2 = zona agrícola

    -- Se agrega el mantenimiento de parques (7) para zonas comerciales
    -- e industriales:
    INSERT INTO [ConceptoCobroDePropiedad] (
        [idConceptoCobro], [idPropiedad], [fechaInicio]
        )
    SELECT CC.[id], i.[id], i.[fechaRegistro]
    FROM inserted i, [dbo].[ConceptoCobro] CC
    WHERE CC.id = 7
        AND i.idTipoZona = 4 OR i.idTipoUsoPropiedad = 5;
        -- 4 = industrial, 5 = comercial
END;