class Approval < ActiveRecord::Base
  attr_accessible :adoption_report_flg, :all_process_end_at, :all_process_start_at, :approval_end_at, :approval_result, :collect_user, :created_at, :created_by, :donate_request_at, :donate_request_replay_at, :donate_request_result, :group_approval_at, :group_approval_result, :group_note, :group_result_reason, :group_user_id, :id, :manifestation_id, :publication_status, :reason, :reception_patron_id, :refuse_at, :sample_arrival_at, :sample_carrier_type, :sample_name, :sample_note, :sample_request_at, :status, :updated_at, :collection_sources,
:approval_extexts_attributes

  has_many :approval_extexts, :dependent => :destroy, :order => "position"
  belongs_to :manifestation
  belongs_to :create_user, :class_name => "User", :foreign_key => :created_by
  belongs_to :group_user, :class_name => "User", :foreign_key => :group_user_id
  belongs_to :reception_patron, :class_name => "Patron", :foreign_key => :reception_patron_id

  accepts_nested_attributes_for :approval_extexts


  before_save :mark_destroy_extext, :set_created_by_extext

  state_machine :status, :initial => :pending do

    event :set_pending do
      transition all => :pending
    end

    event :set_start_approval do
      transition all => :start_approval
    end

    event :set_sample_requested do
      transition all => :sample_requested
    end

    event :set_sample_arrival do
      transition all => :sample_arrival
    end

    event :set_group_approved do
      transition all => :group_approved
    end

    event :set_end_approved do
      transition all => :end_approved
    end

    event :set_donate_requested do
      transition all => :donate_requested
    end

    event :set_replied_donate_request do
      transition all => :replied_donate_request
    end
    event :set_all_process_end do
      transition all => :all_process_end
    end
  end

  def check_status
    if self.all_process_start_at

      if self.all_process_end_at
        self.set_all_process_end
      else
         if self.donate_request_replay_at || self.refuse_at
          self.set_replied_donate_request
        else
          if self.donate_request_at
            self.set_donate_requested
          else
            if self.approval_end_at
              self.set_end_approved
            else
              if self.group_approval_at
                self.set_group_approved
              else
                if self.sample_arrival_at
                  self.set_sample_arrival
                else
                  if self.sample_request_at
                    self.set_sample_requested
                  else
                    self.set_start_approval
                  end
                end
              end
            end
          end
        end
      end
    else
      self.set_pending
    end
  end 

  def self.struct_user_selects
    struct_user = Struct.new(:id, :text)
    @struct_user_array = []
    struct_select = User.all
    struct_select.each do |user|
      @struct_user_array << struct_user.new(user.id, user.username)
    end
    return @struct_user_array
  end


  def self.struct_patron_selects
    struct_patron = Struct.new(:id, :text)
    @struct_patron_array = []
    type_id = PatronType.find(:first, :conditions => ["name = ?", 'Contact'])
    struct_select = Patron.find(:all, :conditions => ["patron_type_id = ?",type_id])
    struct_select.each do |patron|
      @struct_patron_array << struct_patron.new(patron.id, patron.full_name)
    end
    return @struct_patron_array
  end


  def mark_destroy_extext
    approval_extexts.each do |extext|
      extext.mark_for_destruction if extext.value.blank? and extext.state.blank?
    end
  end

  def set_created_by_extext
    approval_extexts.each do |extext|
      extext.created_by = User.current_user.id unless extext.created_by
    end
  end



  paginates_per 10

end
