/*
    Procedimiento para borrar todas las tablas de la base de datos

    (El orden de las tablas toma en cuenta las relaciones, para que no
    dé un error de referencias)
*/

DROP TABLE dbo.Errors;
DROP TABLE dbo.FacturaConArreglo;
DROP TABLE dbo.DetalleConceptoCobroArreglo;
DROP TABLE dbo.MovimientoArreglo;
DROP TABLE dbo.TipoMovimientoArreglo;
DROP TABLE dbo.ArregloDePago;
DROP TABLE dbo.EstadoDeArreglo;
DROP TABLE dbo.TasaInteresArreglo;
DROP TABLE dbo.EventLog;
DROP TABLE dbo.EntityType;
DROP TABLE dbo.ParametroSistema;
DROP TABLE dbo.TipoParametroSistema;
DROP TABLE dbo.ConceptoCobroReconexionAgua;
DROP TABLE dbo.ConceptoCobroInteresesMoratorios;
DROP TABLE dbo.ConceptoCobroParques;
DROP TABLE dbo.ConceptoCobroBasura;
DROP TABLE dbo.ConceptoCobroImpuestoPropiedad;
DROP TABLE dbo.ConceptoCobroPatente;
DROP TABLE dbo.ConceptoCobroAgua;
DROP TABLE dbo.OrdenReconexion;
DROP TABLE dbo.OrdenCorta;
DROP TABLE dbo.EstadoOrdenCorta;
DROP TABLE dbo.DetalleConceptoCobroAgua;
DROP TABLE dbo.MovimientoConsumo;
DROP TABLE dbo.TipoMovimientoConsumo;
DROP TABLE dbo.AguaDePropiedad;
DROP TABLE dbo.DetalleConceptoCobro;
DROP TABLE dbo.ConceptoCobroDePropiedad;
DROP TABLE dbo.ConceptoCobro;
DROP TABLE dbo.TipoMontoConceptoCobro;
DROP TABLE dbo.TipoPeriodoConceptoCobro;
DROP TABLE dbo.Factura;
DROP TABLE dbo.EstadoFactura;
DROP TABLE dbo.Pago;
DROP TABLE dbo.TipoMedioPago;
DROP TABLE dbo.UsuarioDePropiedad;
DROP TABLE dbo.PropietarioDePropiedad;
DROP TABLE dbo.Usuario;
DROP TABLE dbo.TipoUsuario;
DROP TABLE dbo.Propiedad;
DROP TABLE dbo.TipoUsoPropiedad;
DROP TABLE dbo.TipoZona;
DROP TABLE dbo.Persona;
DROP TABLE dbo.TipoDocumentoId;
DROP TABLE dbo.ErroresDefinidos;