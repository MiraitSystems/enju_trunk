class Abbreviation < ActiveRecord::Base
  attr_accessible :keyword, :v

  # キーワードの検証
  validate :val_keyword

  # 既に登録されているキーワードは登録不可
  validates_uniqueness_of :keyword

  def val_keyword
    errors.add(:keyword) unless
    (ApplicationController.check_first_big?(keyword) or
     ApplicationController.check_first_numeric?(keyword)) and
    not ApplicationController.check_middle_big?(keyword) and
    not ApplicationController.check_middle_mark?(keyword) and
    not ApplicationController.exists_space?(keyword)
  end

  def self.get_abbreviation(bookname)
    merge_v = ""
    bookname.split(" ").each do |key|
      merge_before_v = ""
      # 先頭が大文字または数字の場合
      if ApplicationController.check_first_big?(key) or
      ApplicationController.check_first_numeric?(key) then
        abbreviation = Abbreviation.where(keyword: key)
        if not abbreviation.empty?
          merge_before_v = abbreviation[0]['v']
        else
          merge_before_v = key
        end
      # 先頭が小文字で、先頭以外に大文字または記号がある場合
      elsif ApplicationController.check_hankaku_string?(key[0]) and
        (ApplicationController.check_middle_big?(key) or 
         ApplicationController.check_middle_mark?(key)) then
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
