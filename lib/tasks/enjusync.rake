require 'digest/sha1'
require 'net/ftp'

SCRIPT_ROOT = "#{EnjuTrunk::Engine.root}/script/enjusync"
INIT_BUCKET = "#{SCRIPT_ROOT}/init-bucket.pl"
SEND_BUCKET = "#{SCRIPT_ROOT}/send-bucket.pl"
RECV_BUCKET = "#{SCRIPT_ROOT}/recv-bucket.pl"
GET_STATUS_FILE = "#{SCRIPT_ROOT}/get-statusfile.pl"

LOGFILE = 'log/sync'

#DUMPFILE_PREFIX = "/var/enjusync"
#DUMPFILE_NAME = "enjudump.marshal"
PERLBIN = "/usr/bin/perl"
#STATUS_FILE = "#{DUMPFILE_PREFIX}/work/status.marshal"

$enju_log_head = ""
$enju_log_tag = ""

require "open3"

def tag_logger(msg)
  Rails.logger.info "#{$enju_log_head} #{$enju_log_tag} #{msg}"
  puts "#{$enju_log_head} #{$enju_log_tag} #{msg}"
end

namespace :enju_trunk do
  namespace :sync do
    desc 'sync first'
    task :first => :environment do
      require File.join(Gem::Specification.find_by_name("enju_trunk").gem_dir, 'app/servies/enjusync.rb')
      Rails.logger = Logger.new(Rails.root.join("#{LOGFILE}-#{Rails.env}.log"))

      $enju_log_head = "sync::first"
      $enju_log_tag = Digest::SHA1.hexdigest(Time.now.strftime('%s'))[-5, 5]

      tag_logger "start #{Time.now}"

      if ENV['EXPORT_FROM']
        last_event_id = Integer(ENV['EXPORT_FROM'])
      else
        tag_logger 'please specify EXPORT_FROM=N'
        fail 'please specify EXPORT_FROM=N'
      end

      basedir = EnjuSyncServices::Sync.master_server_dir
      dumpfiledir = "#{basedir}/#{last_event_id}"
      dumpfile = "#{dumpfiledir}/#{EnjuSyncServices::Sync::DUMPFILE_NAME}"

      tag_logger "last_id=#{last_event_id} dumpfiledir=#{dumpfiledir} dumpfile=#{dumpfile} "

      tag_logger "mkdir_p begin"
      FileUtils.mkdir_p(dumpfiledir)
      tag_logger "mkdir_p end"

      tag_logger "call task [enju::sync::export] start"

      ENV['EXPORT_FROM'] = last_event_id.to_s
      ENV['DUMP_FILE'] = dumpfile
      Rake::Task["enju:sync:export"].invoke

      tag_logger "call task [enju::sync::export] end"

      EnjuSyncServices::Sync.marshal_file_push(last_event_id)

      tag_logger "end (NormalEnd)"
    end

    desc 'Scheduled process'
    task :scheduled_export => :environment do
      require File.join(Gem::Specification.find_by_name("enju_trunk").gem_dir, 'app/servies/enjusync.rb')
      Rails.logger = Logger.new(Rails.root.join("#{LOGFILE}-#{Rails.env}.log"))

      $enju_log_head = "sync::scheduled_export"
      $enju_log_tag = Digest::SHA1.hexdigest(Time.now.strftime('%s'))[-5, 5]

      tag_logger "start #{Time.now}"
      tag_logger "init_bucket=#{INIT_BUCKET}"
      tag_logger "send_bucket=#{SEND_BUCKET}"

      last_id = Version.last.id
      dumpfiledir = "#{DUMPFILE_PREFIX}/#{last_id}"
      dumpfile = "#{dumpfiledir}/#{DUMPFILE_NAME}"

      # a.業務側からWebOPAC側に接続し、5)のstatusfileを取得し work/marshal.status に保存。
      #Dir::chdir(SCRIPT_ROOT)  
      #tag_logger "call task [get_status_file] start"
      # sh "#{PERLBIN} #{GET_STATUS_FILE}"
      EnjuSyncServices::Sync.status_file_get
      #tag_logger "call task [get_status_file] end"

      #
      tag_logger "mkdir_p begin"
      FileUtils.mkdir_p(dumpfiledir)
      tag_logger "mkdir_p end"

      # b.同期データを出力
      ENV['STATUS_FILE'] = STATUS_FILE
      ENV['DUMP_FILE'] = dumpfile
      Rake::Task["enju:sync:export"].invoke

      # c.バケット作成, d.データ転送
      EnjuSync.ftpsyncpush(last_id) 
    end

    desc 'Scheduled import process on opac(slave)'
    task :scheduled_import => :environment do
      require File.join(Gem::Specification.find_by_name("enju_trunk").gem_dir, 'app/servies/enjusync.rb')
      Rails.logger = Logger.new(Rails.root.join("#{LOGFILE}-#{Rails.env}.log"))

      $enju_log_head = "sync::scheduled_import"
      $enju_log_tag = Digest::SHA1.hexdigest(Time.now.strftime('%s'))[-5, 5]

      tag_logger "start #{Time.now}"
    
      EnjuSyncServices::Sync.marshal_file_recv

      tag_logger "end (NormalEnd)"
    end
  end
end
