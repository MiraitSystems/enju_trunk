class Identifier < ActiveRecord::Base
  default_scope :order => 'position'
  attr_accessible :body, :identifier_type_id, :manifestation_id, :primary, :position, :_delete
  belongs_to :identifier_type
  belongs_to :manifestation

  validates_presence_of :body
  validates :identifier_type_id, :uniqueness => {:scope => :manifestation_id, :message => I18n.t('activerecord.errors.attributes.identifier.duplicate_identifier_type')}
  validate :check_identifier
  before_save :convert_isbn

  acts_as_list :scope => :manifestation_id
  normalize_attributes :body

  def check_identifier
    case identifier_type.try(:name)
    when 'isbn'
      unless StdNum::ISBN.valid?(body)
        errors.add(:body, I18n.t('activerecord.errors.attributes.identifier.invalid_body', :body => self.body))
      end

    when 'issn'
      unless StdNum::ISSN.valid?(body)
        errors[:base] << I18n.t('activerecord.errors.attributes.identifier.invalid_body', :body => self.body)
      end

    when 'lccn'
      unless StdNum::LCCN.valid?(body)
        errors[:base] << I18n.t('activerecord.errors.attributes.identifier.invalid_body', :body => self.body)
      end
    end
  end

  def convert_isbn
    if identifier_type.name == 'isbn'
      lisbn = Lisbn.new(body)
      if lisbn.isbn
        if lisbn.isbn.length == 10
          self.body = lisbn.isbn13
        end
      end
    end
  end

  def hyphenated_isbn
    if identifier_type.name == 'isbn'
      lisbn = Lisbn.new(body)
      lisbn.parts.join('-')
    end
  end
end

# == Schema Information
#
# Table name: identifiers
#
#  id                 :integer          not null, primary key
#  body               :string(255)      not null
#  identifier_type_id :integer          not null
#  manifestation_id   :integer
#  primary            :boolean
#  position           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

