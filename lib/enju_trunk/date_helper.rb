#-*- encoding: utf-8 -*-
class Date 
  def self.enju_wareki2yyyy(gengou, yy)
    return nil unless Wareki::GENGOUS.key?(gengou)
    if yy.class == String
      yyi = yy.to_i
    else
      yyi = yy
    end
    return (Wareki::GENGOUS[gengou].from[0..3].to_i) - 1 + yyi
  end

  def self.enju_generate_merge_range(pub_date_from_str, pub_date_to_str)
    if pub_date_from_str.present?
      from4, to4 = enju_hiduke2yyyymmdd_sub(pub_date_from_str)
    end
    if pub_date_to_str.present?
      from5, to5 = enju_hiduke2yyyymmdd_sub(pub_date_to_str)
    end
    from0 = from4
    to0 = (to5.present?)?(to5):(to4)
    return from0, to0
  end

  def self.enju_hiduke2yyyymmdd_sub(datestr)
    yyyymmdd_from = nil 
    yyyymmdd_to = nil 
    dfrom = nil 
    dto = nil

    return nil, nil if datestr.blank?

    orgstr = datestr.dup

    pattern_hash = {
      "一"=>'1', "二"=>'2', "三"=>'3', "四"=>'4', "五"=>'5',
      "六"=>'6', "七"=>'7', "八"=>'8', "九"=>'9', "〇"=>'0',
      "元"=>'1',
    } 

    datestr.strip!
    datestr.delete!("[]?？()（）") 
    datestr.delete!(" 　")                  # 半角全角スペースを削除 
    datestr = NKF.nkf('-m0Z1 -w', datestr)  # 全角数字を半角に変換
    datestr.gsub!(/[一二三四五六七八九〇元]/, pattern_hash) # 漢数字を半角数字に変換
    datestr.upcase!                         # アルファベット半角小文字を半角大文字に変換
    datestr.gsub!(".", "/")
    datestr.gsub!("-", "/")

    begin
      #i = GENGOUS.keys.index(datestr[0, 2])
      headstr = datestr[0, 2]
      i = nil
      Wareki::GENGOUS.each_with_index do |a, index|
        if headstr.index(a[0]) == 0
          i = index ; break 
        end
      end

      if i.present?
        #puts "i=#{i} key=#{GENGOUS.keys[i]} datestr=#{datestr}"
        datestr.gsub!("年", "/")
        datestr.gsub!("月", "/")
        datestr.gsub!("日", "/")

        # 和暦
        if datestr.match(/^(#{Wareki::GENGOUS.keys[i]})(\d{1,2})\/(\d{1,2})\/(\d{1,2})/)
          syyyy = enju_wareki2yyyy($1, $2.to_i)
          dfrom = dto = Date.new(syyyy, $3.to_i, $4.to_i)
        elsif datestr.match(/(#{Wareki::GENGOUS.keys[i]})(\d{1,2})\/(\d{1,2})/)
          syyyy = enju_wareki2yyyy($1, $2)
          dfrom = Date.new(syyyy, $3.to_i)
          dto = Date.new(syyyy, $3.to_i).end_of_month
        elsif datestr.match(/(#{Wareki::GENGOUS.keys[i]})(\d{1,2})/)
          syyyy = enju_wareki2yyyy($1, $2)
          dfrom = Date.new(syyyy)
          dto = Date.new(syyyy).end_of_year
        else
          i = Wareki::GENGOUS.keys.index(datestr)
          if i.present?
            dfrom = Date.strptime(Wareki::GENGOUS[datestr].from, '%Y%m%d')
            dto = Date.strptime(Wareki::GENGOUS[datestr].to, '%Y%m%d')
          else
            puts "format error (2) #{datestr}"
          end
        end
        yyyymmdd_from = dfrom.strftime("%Y%m%d") if dfrom
        yyyymmdd_to = dto.strftime("%Y%m%d") if dto
      elsif datestr.match(/^\d{4}/)
        datestr.gsub!("年", "/")
        datestr.gsub!("月", "/")
        datestr.gsub!("日", "/")
        #puts "datestr=#{datestr}"
        # 西暦
        if datestr.match(/^(\d{4})\/(\d{1,2})\/(\d{1,2})/)
          dfrom = dto = Date.new($1.to_i, $2.to_i, $3.to_i)
        elsif datestr.match(/^(\d{4})\/(\d{1,2})/)
          dfrom = Date.new($1.to_i, $2.to_i)
          dto = Date.new($1.to_i, $2.to_i).end_of_month
        elsif datestr.match(/^(\d{4})/)
          dfrom = Date.new($1.to_i)
          dto = Date.new($1.to_i).end_of_year
        else
          puts "format error (3) #{datestr}"
        end
        yyyymmdd_from = dfrom.strftime("%Y%m%d") if dfrom
        yyyymmdd_to = dto.strftime("%Y%m%d") if dto
      else
        puts "format error (1) #{datestr}"
      end
    rescue
      puts "format error (9) msg=#{$!}"
        puts "datestr=#{datestr}"
        puts $@
    end
    return yyyymmdd_from, yyyymmdd_to
  end

  def self.expand_date(datestr, options = { mode: 'from' })
    # 西暦もしくは和暦をYYYYMMDD(from,to)の範囲に変換しtime型で返す。
    # 西暦の場合は、半角のハイフンをセパレータとする。
    # 一致しない場合は、nil,nil を返す
    # 昭和49年 => 19740101,19741231
    # 昭和49年3月 => 19740301,19740331
    # 昭和49年3月9日 => 19740309,19740309
    # 1974 => 19740101,19741231
    # 1974-3 => 19740301,19740331
    # 1974-3-9 => 19740309,19740331
    return nil if datestr.blank?
    yyyymmdd_from = nil 
    yyyymmdd_to = nil 
    time = nil

    #puts "datestr0=#{datestrs[0]} datestr1=#{datestrs[1]}"
    from0, to0 = enju_hiduke2yyyymmdd_sub(datestr)
    if from0 
      if options[:mode] == 'from'
        date  = from0
      else
        date  = to0
      end
      year  = date.slice(0, 4).to_i
      month = date.slice(4, 2).to_i
      day   = date.slice(6, 2).to_i
      time = Time.local(year, month, day) 
    end

    return time
  end
end
