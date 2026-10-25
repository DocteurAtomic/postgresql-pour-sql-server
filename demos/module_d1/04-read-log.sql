-- ci: skip (reads the log files of the throwaway container, logging_collector on)
-- Clip D1.4: the log read from SQL, like xp_readerrorlog.
select pg_current_logfile();
select name, size from pg_ls_logdir() order by modification;
-- The last lines of the current file, in order.
select line
from (select line, n
      from regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
           with ordinality as t(line, n)
      where line <> ''
      order by n desc
      limit 3) as last_lines
order by n;
