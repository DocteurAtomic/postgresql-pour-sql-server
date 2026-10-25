-- Exercise of module 5, the query. Lab database (pachadataformation), psql.
-- Enrollments per course: inscription.inscription, stage.session, stage.stage.
-- No foreign key links inscription.sessionid to stage.session: the join is written
-- on sessionid, then on stageid.
select st.stageid, st.categorie, count(*) as enrollments
from inscription.inscription as i
join stage.session as s on s.sessionid = i.sessionid
join stage.stage as st on st.stageid = s.stageid
group by st.stageid, st.categorie;
