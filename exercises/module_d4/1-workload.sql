-- Exercise D4: the workload of the application, a day of PachaDataFormation in a few
-- seconds. Lab database, psql. Read only: run it between two snapshots of the counters.
--   docker compose exec -T db psql -U postgres -d pachadataformation < exercises/module_d4/1-workload.sql
do $$
declare
    r record;
    n bigint;
begin
    -- The office: a contact found by name, then its record, its address and its inscriptions.
    for r in select contactid, nom, adressepostaleid from contact.contact
             where nom is not null order by contactid limit 200 loop
        select count(*) into n from contact.contact where nom = r.nom;
        select count(*) into n from contact.contact where contactid = r.contactid;
        select count(*) into n from contact.adresse where adresseid = r.adressepostaleid;
        select count(*) into n from inscription.inscription where contactid = r.contactid;
    end loop;
    -- The catalog: the sessions of a course in a language, and one session.
    for r in select stageid, languecd from stage.stagelangue order by stageid, languecd loop
        select count(*) into n from stage.session where stageid = r.stageid and languecd = r.languecd;
    end loop;
    for r in select sessionid from stage.session order by sessionid limit 200 loop
        select count(*) into n from stage.session where sessionid = r.sessionid;
    end loop;
    -- The accounts: the invoices of a day, the reminders, one invoice.
    for r in select distinct datefacture from inscription.facture
             where datefacture >= date '2010-01-01' order by 1 limit 100 loop
        select count(*) into n from inscription.facture where datefacture = r.datefacture;
        select count(*) into n from inscription.facture where relance = 2 and datefacture >= r.datefacture;
    end loop;
    for r in select facturecd from inscription.facture order by facturecd limit 100 loop
        select count(*) into n from inscription.facture where facturecd = r.facturecd;
    end loop;
    -- The mailing: the towns of a postcode.
    for r in select distinct codepostal from reference.ville order by 1 limit 100 loop
        select count(*) into n from reference.ville where codepostal = r.codepostal;
    end loop;
end
$$;
