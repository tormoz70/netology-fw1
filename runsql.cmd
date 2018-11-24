chcp 65001
set pghome=D:\PostgreSQL\pg10
set pghost=localhost
set pgport=5432
set pgpwd=root

set PGPASSWORD=%pgpwd%
set PGCLIENTENCODING='UTF-8'
set ON_ERROR_STOP=on

%pghome%\bin\psql -h %pghost% -p %pgport% -U postgres -d postgres -a -f sqls.sql
