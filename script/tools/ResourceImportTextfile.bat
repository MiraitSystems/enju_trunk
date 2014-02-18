cd C:\Sites\enju_trunk
rails runner 'ResourceImportTextfile.import' > C:\Sites\enju_trunk\log\cron_log.log 2>&1
cd C:\Sites\enju_trunk
rails runner 'PatronImportFile.stucked.destroy_all; EventImportFile.stucked.destroy_all; ResourceImportFile.stucked.destroy_all' > C:\Sites\enju_trunk\log\cron_log.log 2>&1
