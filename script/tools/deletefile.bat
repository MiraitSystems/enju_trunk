cd C:\backup\db
forfiles /D -5 /c "cmd /c del /Q @file" > C:\Sites\enju_trunk\log\cron_log.log 2>&1
cd C:\Sites\enju_trunk\log
forfiles /D -5 /c "cmd /c del /Q @file" > C:\Sites\enju_trunk\log\cron_log.log 2>&1
