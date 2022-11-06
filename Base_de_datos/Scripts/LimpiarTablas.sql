USE [proyecto]

--borrado de la informacion de todas las tablas
DELETE dbo.Errors;
DELETE dbo.EventLog;
DELETE dbo.EntityType;
DELETE dbo.ParametroSistema;
DELETE dbo.TipoParametroSistema;
DELETE dbo.ConceptoCobroReconexionAgua;
DELETE dbo.ConceptoCobroInteresesMoratorios;
DELETE dbo.ConceptoCobroParques;
DELETE dbo.ConceptoCobroBasura;
DELETE dbo.ConceptoCobroImpuestoPropiedad;
DELETE dbo.ConceptoCobroPatente;
DELETE dbo.ConceptoCobroAgua;
DELETE dbo.OrdenReconexion;
DELETE dbo.OrdenCorta;
DELETE dbo.EstadoOrdenCorta;
DELETE dbo.DetalleConceptoCobroAgua;
DELETE dbo.MovimientoConsumo;
DELETE dbo.TipoMovimientoConsumo;
DELETE dbo.AguaDePropiedad;
DELETE dbo.DetalleConceptoCobro;
DELETE dbo.ConceptoCobroDePropiedad;
DELETE dbo.ConceptoCobro;
DELETE dbo.TipoMontoConceptoCobro;
DELETE dbo.TipoPeriodoConceptoCobro;
DELETE dbo.Factura;
DELETE dbo.EstadoFactura;
DELETE dbo.Pago;
DELETE dbo.TipoMedioPago;
DELETE dbo.UsuarioDePropiedad;
DELETE dbo.PropietarioDePropiedad;
DELETE dbo.Usuario;
DELETE dbo.TipoUsuario;
DELETE dbo.Propiedad;
DELETE dbo.TipoUsoPropiedad;
DELETE dbo.TipoZona;
DELETE dbo.Persona;
DELETE dbo.TipoDocumentoId;
--DELETE dbo.socorro;
DELETE dbo.ErroresDefinidos;


-- reiniciamos el PK de las tablas
DBCC CHECKIDENT (Errors, RESEED, 0);
DBCC CHECKIDENT (EventLog, RESEED, 0);
DBCC CHECKIDENT (EntityType, RESEED, 0);
DBCC CHECKIDENT (OrdenReconexion, RESEED, 0);
DBCC CHECKIDENT (OrdenCorta, RESEED, 0);
DBCC CHECKIDENT (MovimientoConsumo, RESEED, 0);
DBCC CHECKIDENT (DetalleConceptoCobro, RESEED, 0);
DBCC CHECKIDENT (ConceptoCobroDePropiedad, RESEED, 0);
DBCC CHECKIDENT (Factura, RESEED, 0);
DBCC CHECKIDENT (UsuarioDePropiedad, RESEED, 0);
DBCC CHECKIDENT (PropietarioDePropiedad, RESEED, 0);
DBCC CHECKIDENT (Usuario, RESEED, 0);
DBCC CHECKIDENT (TipoUsuario, RESEED, 0);
DBCC CHECKIDENT (Propiedad, RESEED, 0);
DBCC CHECKIDENT (Persona, RESEED, 0);
--DBCC CHECKIDENT (socorro, RESEED, 0);
DBCC CHECKIDENT (ErroresDefinidos, RESEED, 0);

DECLARE @SQL VARCHAR(MAX)
SELECT @SQL = BulkColumn
FROM OPENROWSET
	( BULK 'D:\Personal\TEC\Universidad\2022-6-2\base\servidores sql\proyecto\BD1Proy\Base_de_datos\Scripts\LeerCatalogo.sql'
	, SINGLE_BLOB ) AS MYTABLE

EXEC(@SQL)