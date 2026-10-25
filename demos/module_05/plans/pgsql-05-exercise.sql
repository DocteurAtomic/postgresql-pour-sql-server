select st.stageid, st.categorie, count(*) as enrollments
from inscription.inscription as i
join stage.session as s on s.sessionid = i.sessionid
join stage.stage as st on st.stageid = s.stageid
group by st.stageid, st.categorie
