-- ci: skip
-- Clip D8.5: the four checks of sqlserver/05-pitfalls.sql, in PostgreSQL. Run by
-- 05-validate.sh in its throwaway container, after the load.
-- 1. MD5 of the UTF-8 bytes, then of the same text converted to code page 1252.
select md5(nomville) as md5_utf8, md5(convert_to(nomville, 'WIN1252')) as md5_win1252,
       octet_length(nomville) as bytes, char_length(nomville) as characters
from reference.ville where villeid = 1;
-- 2. Distinct values: the collation of the database (en_US.utf8) is case-sensitive.
select count(distinct nom) as default_collation, count(distinct nom collate "C") as c,
       count(distinct lower(nom)) as lower
from contact.contact;
-- 3. The smallest e-mail address, by collation.
select min(email) as default_collation, min(email collate "C") as c from contact.contact;
-- 4. A char(10): char_length() drops the trailing blanks, octet_length() counts them.
select statut, char_length(statut), octet_length(statut)
from stage.session where statut = 'TERMINEE' limit 1;
