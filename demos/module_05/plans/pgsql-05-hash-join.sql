select s.sessionid, count(*) as enrollments
from stage.session as s
join inscription.inscription as i on i.sessionid = s.sessionid
where s.datedebut >= date '2020-01-01'
group by s.sessionid
