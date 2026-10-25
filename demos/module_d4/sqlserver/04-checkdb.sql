-- Clip D4.4, SQL Server side: DBCC CHECKDB, in a database of the module, MD4PgCheck,
-- created and dropped here (CHECKDB creates an internal snapshot of the database it checks).
-- SQL Server 2022, sqlcmd, connected to master. Nothing is written in PachaDataFormation.
set nocount on;
if db_id('MD4PgCheck') is not null drop database MD4PgCheck;
create database MD4PgCheck;
go
use MD4PgCheck;
select * into dbo.Facture from PachaDataFormation.Inscription.Facture;
alter table dbo.Facture add constraint pk_Facture primary key (FactureCd);
create index nix_Facture_DateFacture on dbo.Facture (DateFacture);
go
-- The whole database: allocation, every table and index, the catalog. The last line sums up.
dbcc checkdb (MD4PgCheck);
go
-- The same, quiet unless something is wrong; PHYSICAL_ONLY reads pages and checksums only.
dbcc checkdb (MD4PgCheck) with no_infomsgs, physical_only;
go
-- One table and its indexes.
dbcc checktable ('dbo.Facture') with no_infomsgs;
go
use master;
drop database MD4PgCheck;
go
