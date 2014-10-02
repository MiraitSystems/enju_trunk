# encoding: utf-8
require 'digest/sha1'
require 'digest/md5'
require 'net/ftp'
require "open3"

module EnjuSyncServices
  class SyncError < StandardError ; end

  module EnjuSyncUtil
    def tag_logger(msg)
      Rails.logger.info "#{$enju_log_head} #{$enju_log_tag} #{msg}"
      puts "#{$enju_log_head} #{$enju_log_tag} #{msg}"
    end

    def tag_notifier(msg, c = caller)
      tag_logger(msg)
      ex = SyncError.new(msg)
      ex.set_backtrace(c)
      sync_notifier(ex)
    end

    def sync_notifier(ex)
      ExceptionNotifier::Rake.maybe_deliver_notification ex
    end
  end

  class Sync
    LOGFILE = 'log/sync.log'

    SLAVE_SERVER_DIR = "/var/enjusync"

    DUMPFILE_PREFIX = "/var/enjusync"
    DUMPFILE_NAME = "enjudump.marshal"
    COMPRESS_FILE_NAME = "dumpfiles.gz"
    STATUS_FILE = "#{DUMPFILE_PREFIX}/work/status.marshal"

    self.extend EnjuSyncUtil

    def self.load_control_file(ctl_file_name)
      return compressed_file_size, md5checksum
    end

    def self.build_bucket(bucket_id)
      # init backet
      work_dir = File.join(DUMPFILE_PREFIX, "#{bucket_id}")
      gzip_file_name = COMPRESS_FILE_NAME
      marsharl_full_name = File.join(work_dir, DUMPFILE_NAME)
      gzip_full_name = File.join(work_dir, gzip_file_name)
      exec_date = Time.now.strftime("%Y%m%d")

      unless FileTest::exist?(marsharl_full_name)
        # marshal ファイルが無い場合、ステータスEND、終了
        ctl_file = File.join(work_dir, "#{exec_date}-END-0.ctl")
        FileUtils.touch(ctl_file, :mtime => Time.now)
        tag_logger("Can not open #{marsharl_full_name} (no update)");
        return
      end

      # marshal ファイルをgzで圧縮する。
      Zlib::GzipWriter.open(gzip_full_name, Zlib::BEST_COMPRESSION) do |gz|
        gz.mtime = File.mtime(marsharl_full_name)
        gz.orig_name = marsharl_full_name
        gz.puts File.open(marsharl_full_name, 'rb') {|f| f.read }
      end

      file_size = File.size(gzip_full_name)
      md5sum = Digest::MD5.file(gzip_full_name).to_s

      ctl_file = File.join(work_dir, "#{exec_date}-RDY-0.ctl")

      # ステータスファイルにファイルサイズとmd5チェックサムを記述する。
      File.open(ctl_file, "w") do |io|
        io.puts file_size
        io.puts md5sum
      end

    end

    def self.push_by_ftp(ftp_site, ftp_user, ftp_password, bucket_id, push_target_files)
      ftp_site_base_dir = SLAVE_SERVER_DIR
      bucket_dir = File.join(ftp_site_base_dir, "#{bucket_id}")

      tag_logger "ftp_site:#{ftp_site} ftp_user:#{ftp_user} bucket_id:#{bucket_id}"
      tag_logger "ftp_site_dir: #{bucket_dir}"

      Net::FTP.open(ftp_site, ftp_user, ftp_password) do |ftp|
        ftp.passive = true

        if ftp.dir(bucket_dir).empty?
          tag_logger "try mkdir: #{bucket_dir}"
          ftp.mkdir(bucket_dir)
        end

        push_target_files.each do |file_name|
          site_file_name = File.join(bucket_dir, File.basename(file_name))
          tag_logger "push file: slave_server_filename: #{site_file_name}"
          ftp.putbinaryfile(file_name, site_file_name)
        end
      end
    end

    def self.marshal_file_recv
      glob_string = "#{DUMPFILE_PREFIX}/[0-9]*/*-[RDY|ERR]-*.ctl"

      # 一番IDが小さい受信可能ファイルを取得( RDY|ERR )
      rdy_ctl_files = Dir.glob(glob_string).sort 
      if rdy_ctl_files.empty?
        # 受信すべきバケットがないので、ログを記録して終了
        tag_logger("receive buckets not exist");
        return
      end 

      rdy_ctl_files.each do |ctl_file_name|
        unless /\w+\/(\d+)-(\w+)-(\d+)\.ctl$/ =~ ctl_file_name
          tar_logger "FATAL: ctl_file error (1) #{target_dir}"
          return
        end
        exec_date = $1
        send_stat = $2
        retry_cnt = $3

        tag_logger "exec_date=#{exec_date} send_stat=#{send_stat} retry_cnt=#{retry_cnt}"

        target_dir = File.dirname(ctl_file_name)
        unless /.*\/(\d)$/ =~ target_dir
          tar_logger "FATAL: ctl_file error (2) #{target_dir}"
          return
        end

        bucket_id = $1

        unless send_stat == "RDY"
          tag_logger "skip: status=#{send_stat} ctl_fil_name=#{ctl_file_name}"
          next
        end

        f = open("foo")
        f.each_line {|line|
          print line
        }
        f.close

        ctl_file_success_name = File.join(target_dir, "#{exec_date}-END-#{retry_cnt}.ctl")

        target_dir_s = File.join(target_dir, "#{COMPRESS_FILE_NAME}.gz")
        push_target_files = Dir.glob(target_dir_s).sort 
        push_target_files << "#{ctl_file_name}"

        Rake::Task["enju:sync:import"].invoke

        tag_logger "rename to #{ctl_file_success_name}"
        File.rename(ctl_file_name, ctl_file_success_name)
      end
 
    end

    def self.marshal_file_push(bucket_id)
      glob_string = "#{DUMPFILE_PREFIX}/[0-9]*/*-[RDY|ERR]-*.ctl"
      ftp_site = SystemConfiguration.get("sync.ftp.site")
      ftp_user = SystemConfiguration.get("sync.ftp.user")
      ftp_password = SystemConfiguration.get("sync.ftp.password")

      if ftp_site.blank?
        tag_notifier "FATAL: configuration (sync.ftp.site) is empty."
        tag_logger "FATAL: see config/config.yml"
       return
      end

      if ftp_user.blank? || ftp_password.blank?
        tag_notifier "FATAL: configuration (sync.ftp.user or sync.ftp.password) is empty."
        tag_logger "FATAL: see config/config.yml"
        return
      end

      # compress marsharl file, create control file and write checksum
      build_bucket(bucket_id)

      # 一番IDが小さい送信可能ファイルを取得( RDY|ERR )
      rdy_ctl_files = Dir.glob(glob_string).sort 
      if rdy_ctl_files.empty?
        # 送信すべきバケットがないので、ログを記録して終了
        tag_logger("sending buckets not exist");
        return
      end

      rdy_ctl_files.each do |ctl_file_name|
        unless /\w+\/(\d+)-(\w+)-(\d+)\.ctl$/ =~ ctl_file_name
          tar_logger "FATAL: ctl_file error (1) #{target_dir}"
          return
        end
        exec_date = $1
        send_stat = $2
        retry_cnt = $3

        tag_logger "exec_date=#{exec_date} send_stat=#{send_stat} retry_cnt=#{retry_cnt}"

        target_dir = File.dirname(ctl_file_name)
        unless /.*\/(\d)$/ =~ target_dir
          tar_logger "FATAL: ctl_file error (2) #{target_dir}"
          return
        end

        bucket_id = $1

        unless send_stat == "RDY"
          tag_logger "skip: status=#{send_stat} ctl_fil_name=#{ctl_file_name}"
          next
        end

        ctl_file_success_name = File.join(target_dir, "#{exec_date}-END-#{retry_cnt}.ctl")

        target_dir_s = File.join(target_dir, "#{COMPRESS_FILE_NAME}.gz")
        push_target_files = Dir.glob(target_dir_s).sort 
        push_target_files << "#{ctl_file_name}"

        push_by_ftp(ftp_site, ftp_user, ftp_password, bucket_id, push_target_files)

        tag_logger "rename to #{ctl_file_success_name}"
        File.rename(ctl_file_name, ctl_file_success_name)
      end
    end
  end
end
