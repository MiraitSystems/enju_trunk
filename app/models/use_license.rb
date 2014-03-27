class UseLicense < ActiveRecord::Base
  attr_accessible :account_kind, :account_name, :account_number, :agency_address, :agency_name, :author, :author_fee, :bank_code, :bank_name, :branch_name, :branch_number, :id, :responsible_mail, :responsible_name, :responsible_tel, :target

  has_one :manifestation

end
