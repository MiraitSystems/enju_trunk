@echo off
SET BACKUPDIR=C:\backup\db\
SET USER=postgres
SET PGPASSWORD=postgres
SET DUMPFILE=pgdump.date%date:~-10,4%%date:~-5,2%%date:~-2,2%%time:~-11,2%%time:~-8,2%%time:~-5,2%.custom

cd C:\Program Files\PostgreSQL\9.3\bin

echo "backup start file: %DUMPFILE%"
pg_dump.exe -U %USER% -Fc enju_production > %BACKUPDIR%%DUMPFILE%
echo done.

cd C:\
