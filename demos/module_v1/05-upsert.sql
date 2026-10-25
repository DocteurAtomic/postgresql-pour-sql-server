-- Clip V1.5: INSERT ... ON CONFLICT, MERGE (15) and MERGE ... RETURNING (17).
-- Lab database, psql. Works on two tables created here and dropped at the end: a price
-- catalog of the PostgreSQL 9 courses, and an import that changes it.
-- Two statements fail on purpose: ON_ERROR_STOP is off around them.
create table outils.mv1_catalog (
    stageid integer primary key,
    titre   text not null,
    prix    numeric(8, 2) not null,
    active  boolean not null default true
);
insert into outils.mv1_catalog (stageid, titre, prix)
select stageid, titre, 3500 from stage.stagelangue where stageid between 113 and 120;

-- The import: two new prices (119, 120) and a new course (200).
create table outils.mv1_import (stageid integer, titre text, prix numeric(8, 2));
insert into outils.mv1_import values
    (119, 'PostgreSQL 9 Optimisation', 3900),
    (120, 'PostgreSQL 9 Prise en Main', 2900),
    (200, 'PostgreSQL 18 pour SQL Server', 3200);

-- The upsert in one statement. EXCLUDED is the row that was refused; OLD and NEW (18) say
-- what changed, OLD being NULL for an inserted row.
insert into outils.mv1_catalog as c (stageid, titre, prix)
select stageid, titre, prix from outils.mv1_import
on conflict (stageid) do update set prix = excluded.prix
returning c.stageid, old.prix as old_price, new.prix as new_price;

-- DO NOTHING: an import replayed changes nothing.
insert into outils.mv1_catalog (stageid, titre, prix)
select stageid, titre, prix from outils.mv1_import
on conflict (stageid) do nothing;

-- The conflict target needs a unique index or constraint; and one statement cannot
-- update the same row twice.
\set ON_ERROR_STOP off
insert into outils.mv1_catalog (stageid, titre, prix)
values (201, 'PostgreSQL 9 Optimisation', 3900)
on conflict (titre) do nothing;
insert into outils.mv1_catalog (stageid, titre, prix)
values (119, 'PostgreSQL 9 Optimisation', 3950), (119, 'PostgreSQL 9 Optimisation', 3990)
on conflict (stageid) do update set prix = excluded.prix;
\set ON_ERROR_STOP on

-- The next import: a new price for 119, a new course 201.
update outils.mv1_import set prix = 4100 where stageid = 119;
insert into outils.mv1_import values (201, 'PostgreSQL 18 Administration', 3400);

-- MERGE: the same import, plus a deactivation of the courses it does not list
-- (WHEN NOT MATCHED BY SOURCE, 17). RETURNING and merge_action() (17) replace OUTPUT $action.
merge into outils.mv1_catalog as c
using outils.mv1_import as i on i.stageid = c.stageid
when matched and c.prix <> i.prix then
    update set prix = i.prix
when not matched then
    insert (stageid, titre, prix) values (i.stageid, i.titre, i.prix)
when not matched by source and c.active then
    update set active = false
returning merge_action() as action, c.stageid, old.prix as old_price, new.prix as new_price,
          new.active;

drop table outils.mv1_import;
drop table outils.mv1_catalog;
