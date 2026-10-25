with s as (select sessionid, stageid, datedebut from stage.session)
select sessionid, datedebut from s where sessionid = 971
