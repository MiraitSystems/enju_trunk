cd C:\Sites\enju_trunk
rails runner 'Reserve.expire; Basket.expire; User.lock_expired_users' > C:\Sites\enju_trunk\log\cron_log.log 2>&1
