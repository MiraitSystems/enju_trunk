cd C:\Sites\enju_trunk
rails runner 'UserCheckoutStat.calculate_stat; UserReserveStat.calculate_stat; ManifestationCheckoutStat.calculate_stat; ManifestationReserveStat.calculate_stat; BookmarkStat.calculate_stat' > C:\Sites\enju_trunk\log\cron_log.log 2>&1
cd C:\Sites\enju_trunk
rails runner 'AccessLog.calc_sum_yesterday' > C:\Sites\enju_trunk\log\cron_log.log 2>&1
