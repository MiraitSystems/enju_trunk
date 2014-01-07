class Abbreviation < ActiveRecord::Base
  attr_accessible :keyword, :v

  def self.get_abbreviation(bookname)
    merge_v = ""
    bookname.split(" ").each do |key|
      abbreviation = Abbreviation.where(keyword: key)
      if ! abbreviation.empty?
        if merge_v == "" then
          merge_v = abbreviation[0]['v']
        else
          merge_v.concat(" ").concat(abbreviation[0]['v'])
        end
      end
    end
    return merge_v
  end
end
