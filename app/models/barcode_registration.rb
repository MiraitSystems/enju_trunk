class BarcodeRegistration
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :first_number, :last_number
  validates :first_number,
    :presence => false, 
    :length   => { maximum: 9 },
    :format   => { with: /^\d+$/ }
  validates :last_number,
    :presence => false, 
    :length   => { maximum: 9 },
    :format   => { with: /^\d+$/ }
  validate :comparison_in_size

  def comparison_in_size
    errors.add(:first_number, I18n.t('barcode_registration.more_than_last_number')) if first_number.to_i > last_number.to_i
  end

  def self.set_data(first_number, last_number)
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8")
    row = []
    first_number.to_i.upto(last_number.to_i) { |num| row << "%09d" % num }
    data << '"'+row.join("\",\n\"")+"\"\n"
  end
 
  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end 

  def persisted?
    false
  end
end
