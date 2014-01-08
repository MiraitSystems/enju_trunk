class Abbreviation < ActiveRecord::Base
  attr_accessible :keyword, :v

  def self.get_abbreviation(bookname)
    merge_v = ""
    bookname.split(" ").each do |key|
      merge_before_v = ""
      # 先頭が大文字または数字の場合
      if ApplicationController.check_first_big?(key) or
      ApplicationController.check_first_numeric?(key) then
        abbreviation = Abbreviation.where(keyword: key)
        if ! abbreviation.empty?
          merge_before_v = abbreviation[0]['v']
        else
          merge_before_v = key
        end
      # 先頭以外に大文字がある場合
      elsif ApplicationController.check_middle_big?(key) then
        merge_before_v = key
      # 上記以外の場合、次の要素へ進む
      else
        next
      end

      if merge_v == "" then
        merge_v = merge_before_v
      else
        merge_v.concat(" ").concat(merge_before_v)
      end
    end
    return merge_v
  end
end
