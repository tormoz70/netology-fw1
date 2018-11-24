chcp 65001 
echo off
set pghome=D:\PostgreSQL\pg10
set pghost=localhost
set pgport=5432
set pgpwd=root

set PGPASSWORD=%pgpwd%
set PGCLIENTENCODING='UTF-8'
set ON_ERROR_STOP=on

echo инициализация базы данных...
%pghome%\bin\psql -h %pghost% -p %pgport% -U postgres -d postgres -a -f crebas.sql
echo база данных инициализированна

echo загрузка данных...
%pghome%\bin\psql -h %pghost% -p %pgport% -U postgres -d postgres -a -f loaddata.sql
echo данные загружены
echo on
