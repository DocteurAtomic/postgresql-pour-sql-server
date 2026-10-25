-- ci: skip
-- Clip D5.1, session C of the scene: connected, between two queries, no transaction.
set application_name = 'md5-idle';
select 1 as connected;
\! sleep 9
