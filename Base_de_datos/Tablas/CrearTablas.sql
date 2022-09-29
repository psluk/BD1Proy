-- Este script es utilizado para crear las tablas
-- También crea las relaciones necesarias (llaves primarias y externas)

-- CATEGORÍA: PERSONAS

CREATE TABLE dbo.TipoDocumentoId
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Columnas
    nombre varchar(32) NOT NULL,
    
    -- Se establece la llave primaria
    CONSTRAINT PK_id PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Persona
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idTipoDocumentoId int NOT NULL,

    -- Otras columnas
    nombre varchar(64) NOT NULL,
    valorDocumentoId varchar(32) NOT NULL,
    telefono1 bigint NOT NULL,
    telefono2 bigint NOT NULL,
    email varchar(128) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_Persona PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Persona_TipoDocumentoId FOREIGN KEY (idTipoDocumentoId)
        REFERENCES dbo.TipoDocumentoId (id)
);

-- CATEGORÍA: USUARIOS

CREATE TABLE dbo.TipoUsuario
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    nombre varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoUsuario PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Usuario
(
    -- Llaves
    id int NOT NULL,
    idTipoUsuario int NOT NULL,

    -- Otras columnas
    nombreDeUsuario varchar(32) NOT NULL,
    clave varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Usuario PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (id)
        REFERENCES dbo.Persona (id),
    CONSTRAINT FK_Usuario_TipoUsuario FOREIGN KEY (idTipoUsuario)
        REFERENCES dbo.TipoUsuario (id)
);

-- CATEGORÍA: PROPIEDADES
CREATE TABLE dbo.TipoUsoTerreno
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    nombre varchar(32) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoUsoTerreno PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.TipoZona
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    nombre varchar(32) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoZona PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Propiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idTipoUsoTerreno int NOT NULL,
    idTipoZona int NOT NULL,

    -- Otras columnas
    numeroFinca int NOT NULL,
    area int NOT NULL,
    valorFiscal bigint NOT NULL,
    fechaRegistro date NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Propiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Propiedad_TipoUsoTerreno FOREIGN KEY (idTipoUsoTerreno)
        REFERENCES dbo.TipoUsoTerreno (id),
    CONSTRAINT FK_Propiedad_TipoZona FOREIGN KEY (idTipoZona)
        REFERENCES dbo.TipoZona (id)
);

-- CATEGORÍA: Propiedad + (Persona o Usuario)

CREATE TABLE dbo.PropietarioDePropiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idPersona int NOT NULL,
    idPropiedad int NOT NULL,

    -- Otras columnas
    fechaInicio date NOT NULL,
    fechaFin date NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_PropietarioDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_PropietarioDePropiedad_Persona FOREIGN KEY (idPersona)
        REFERENCES dbo.Persona (id),
    CONSTRAINT FK_PropietarioDePropiedad_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id)
);

CREATE TABLE dbo.UsuarioDePropiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idUsuario int NOT NULL,
    idPropiedad int NOT NULL,

    -- Otras columnas
    fechaInicio date NOT NULL,
    fechaFin date NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_UsuarioDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_UsuarioDePropiedad_Persona FOREIGN KEY (idUsuario)
        REFERENCES dbo.Usuario (id),
    CONSTRAINT FK_UsuarioDePropiedad_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id)
);

-- CATEGORÍA: Facturas

CREATE TABLE dbo.EstadoFactura
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    descripcion varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_EstadoFactura PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Factura
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idPropiedad int NOT NULL,
    idEstadoFactura int NOT NULL,

    -- Otras columnas
    fechaGeneracion date NOT NULL,
    fechaVencimiento date NOT NULL,
    totalOriginal money NOT NULL,
    totalActual money NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Factura PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Factura_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id),
    CONSTRAINT FK_Factura_EstadoFactura FOREIGN KEY (idEstadoFactura)
        REFERENCES dbo.EstadoFactura (id)
);

-- CATEGORÍA: Conceptos de cobro

CREATE TABLE dbo.ConceptoCobro
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    nombre varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobro PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.ConceptoCobroDePropiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idPropiedad int NOT NULL,
    idConceptoCobro int NOT NULL,

    -- Otras columnas
    fechaInicio date NOT NULL,
    fechaFin date NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroDePropiedad_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id),
    CONSTRAINT FK_ConceptoCobroDePropiedad_ConceptoCobro FOREIGN KEY (idConceptoCobro)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.DetalleConceptoCobro
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idFactura int NOT NULL,
    idConceptoCobro int NOT NULL,

    -- Otras columnas
    monto money NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_DetalleConceptoCobro PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_DetalleConceptoCobro_Factura FOREIGN KEY (idFactura)
        REFERENCES dbo.Factura (id),
    CONSTRAINT FK_DetalleConceptoCobro_ConceptoCobro FOREIGN KEY (idConceptoCobro)
        REFERENCES dbo.ConceptoCobro (id)
);

-- CATEGORÍA: Agua

CREATE TABLE dbo.AguaDePropiedad
(
    -- Llaves
    id int NOT NULL,

    -- Otras columnas
    numeroMedidor int NOT NULL,
    consumoAcumulado float NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_AguaDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_AguaDePropiedad_ConceptoCobroDePropiedad FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobroDePropiedad (id)
);

CREATE TABLE dbo.TipoMovimientoConsumo
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    nombre varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoMovimientoConsumo PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.MovimientoConsumo
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idTipoMovimiento int NOT NULL,
    idAguaDePropidad int NOT NULL,

    -- Otras columnas
    fecha date NOT NULL,
    consumoMovimiento money NOT NULL,
    consumoAcumulado money NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_MovimientoConsumo PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_MovimientoConsumo_TipoMovimientoConsumo
        FOREIGN KEY (idTipoMovimiento)
        REFERENCES dbo.TipoMovimientoConsumo (id),
    CONSTRAINT FK_MovimientoConsumo_AguaDePropiedad
        FOREIGN KEY (idAguaDePropidad)
        REFERENCES dbo.AguaDePropiedad (id),
);

CREATE TABLE dbo.DetalleConceptoCobroAgua
(
    -- Llaves
    idDetalleConceptoCobro int NOT NULL,
    idMovimiento int NOT NULL UNIQUE,

    -- Se establece la llave primaria
    CONSTRAINT PK_DetalleConceptoCobroAgua PRIMARY KEY CLUSTERED
        (idDetalleConceptoCobro),

    -- Se asocian las llaves externas
    CONSTRAINT FK_DetalleConceptoCobroAgua_DetalleConceptoCobro
        FOREIGN KEY (idDetalleConceptoCobro)
        REFERENCES dbo.DetalleConceptoCobro (id),
    CONSTRAINT FK_DetalleConceptoCobroAgua_MovimientoConsumo
        FOREIGN KEY (idMovimiento)
        REFERENCES dbo.MovimientoConsumo (id)
);

CREATE TABLE dbo.OrdenCorta
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idFactura int NOT NULL UNIQUE,
    idPropiedad int NOT NULL,
    
    -- Otras columnas
    numeroMedidor int NOT NULL,
    fechaOperacion date NOT NULL,
    estadoPago int NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_OrdenCorta PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_OrdenCorta_Factura FOREIGN KEY (idFactura)
        REFERENCES dbo.Factura (id),
    CONSTRAINT FK_OrdenCorta_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id)
);

CREATE TABLE dbo.OrdenReconexion
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idFactura int NOT NULL,
    idOrdenCorta int NOT NULL UNIQUE,
    
    -- Otras columnas
    numeroMedidor int NOT NULL,
    fechaReconexion date NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_OrdenReconexion PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_OrdenReconexion_Factura FOREIGN KEY (idFactura)
        REFERENCES dbo.Factura (id),
    CONSTRAINT FK_OrdenReconexion_OrdenCorta FOREIGN KEY (idOrdenCorta)
        REFERENCES dbo.OrdenCorta (id)
);

-- VALORES FIJOS
INSERT INTO dbo.EstadoFactura (descripcion)
    VALUES ('Pendiente'), ('Pagado normalmente'),
        ('Pagado con arreglo de pago'), ('Anulado')