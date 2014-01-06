class Abbreviation < ActiveRecord::Base
  attr_accessible :keyword, :v

  def self.get_abbreviation(bookname)
    merge_v = ""
    bookname.split(" ").each do |key|
      @abberviation = Abbreviations.find(key)
      if merge_v == "" then
        merge_v = abbreviation.v
      else
        merge_v.concat(" ").concat(abbreviation.v)
      end
    end
    return merge_v
  end
end
