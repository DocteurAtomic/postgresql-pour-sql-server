-- ci: skip
-- Clip D8.6: the first write of an application after the cutover, one session and one town.
-- Run by 06-cutover.sh in its throwaway container; each statement may fail on its own.
insert into stage.session (stageid, languecd, datedebut, prix, statut, datecreation, duree, intraentrerprise)
values (1, 'FR', date '2027-01-11', 1350, 'PLANIFIEE', current_date, 3, false)
returning sessionid;
insert into reference.ville (nomville, codepostal, payscd)
values ('Ville nouvelle', '99999', 'FRA')
returning villeid;
