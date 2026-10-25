-- Clip D2.4: encrypting a column with pgcrypto, created by 00-setup.sql. Lab database,
-- psql. Creates outils.md2_contact, dropped by 99-cleanup.sql. The key is a demonstration
-- value; one statement fails on purpose: ON_ERROR_STOP is off around it.

-- The phone numbers of the contacts, encrypted with a passphrase (OpenPGP, AES-128).
create table outils.md2_contact as
select contactid, nom, pgp_sym_encrypt(telephone, 'demo-key') as telephone_chiffre
from contact.contact
where telephone is not null;

select count(*) as contacts, pg_size_pretty(sum(octet_length(telephone_chiffre))) as encrypted_size
from outils.md2_contact;

select contactid, nom, left(encode(telephone_chiffre, 'hex'), 32) || '...' as stored
from outils.md2_contact
order by contactid
limit 3;

-- Decrypting: the key travels in the query, and the server decrypts.
select contactid, nom, pgp_sym_decrypt(telephone_chiffre, 'demo-key') as telephone
from outils.md2_contact
order by contactid
limit 3;

\set ON_ERROR_STOP off
select pgp_sym_decrypt(telephone_chiffre, 'wrong-key') as telephone
from outils.md2_contact
order by contactid
limit 1;
\set ON_ERROR_STOP on

-- An index on the encrypted column cannot serve a search by phone number: every
-- encryption of the same value differs (random session key and salt).
select pgp_sym_encrypt('01 02 03 04 05', 'demo-key') = pgp_sym_encrypt('01 02 03 04 05', 'demo-key')
       as same_ciphertext;
