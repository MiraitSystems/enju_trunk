class Approval < ActiveRecord::Base
  attr_accessible :adoption_report_flg, :all_process_end_at, :all_process_start_at, :approval_end_at, :approval_result, :collect_user, :created_at, :created_by, :donate_request_at, :donate_request_replay_at, :donate_request_result, :group_approval_at, :group_approval_result, :group_note, :group_result_reason, :group_user_id, :id, :manifestation_id, :publication_status, :reason, :reception_agent_id, :refuse_at, :sample_arrival_at, :sample_carrier_type, :sample_name, :sample_note, :sample_request_at, :status, :updated_at, :collection_sources,
                  :approval_extexts_attributes,
                  :approval_identifier, :thrsis_review_flg, :ja_text_author_summary_flg, :en_text_author_summary_flg, :proceedings_number_of_year, :excepting_number_of_year, :four_priority_areas, :document_classification_1, :document_classification_2

  attr_accessor :identifier

  has_many :approval_extexts, :dependent => :destroy, :order => "position"
  belongs_to :manifestation
  belongs_to :create_user, :class_name => "User", :foreign_key => :created_by
  belongs_to :group_user, :class_name => "User", :foreign_key => :group_user_id
  belongs_to :reception_agent, :class_name => "Agent", :foreign_key => :reception_agent_id

  belongs_to :thrsis_review_flg_code, :class_name => 'Keycode', :foreign_key => 'thrsis_review_flg'
  belongs_to :ja_text_author_summary_flg_code, :class_name => 'Keycode', :foreign_key => 'ja_text_author_summary_flg'
  belongs_to :en_text_author_summary_flg_code, :class_name => 'Keycode', :foreign_key => 'en_text_author_summary_flg'
  belongs_to :four_priority_areas_code, :class_name => 'Keycode', :foreign_key => 'four_priority_areas'
  belongs_to :document_classification_1_code, :class_name => 'Keycode', :foreign_key => 'document_classification_1'
  belongs_to :document_classification_2_code, :class_name => 'Keycode', :foreign_key => 'document_classification_2'

  accepts_nested_attributes_for :approval_extexts

  validates_uniqueness_of :approval_identifier, :allow_nil => true, :allow_blank => true

  validate :validate_identifier
  def validate_identifier
    return if self.manifestation_id

    if self.identifier.blank?
    errors.add(I18n.t('activerecord.attributes.manifestation.identifier'), I18n.t('approval.no_blank_identifier'))
    else
      manifestation = Manifestation.find_by_identifier(self.identifier)
      if manifestation
        self.manifestation_id = manifestation.id
      else
        errors.add(I18n.t('activerecord.attributes.manifestation.identifier'), I18n.t('approval.no_matches_found_manifestation'))
      end
    end
  end


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


  def self.struct_agent_selects
    struct_agent = Struct.new(:id, :text)
    @struct_agent_array = []
    type_id = AgentType.find(:first, :conditions => ["name = ?", 'Contact'])
    struct_select = Agent.find(:all, :conditions => ["agent_type_id = ?",type_id])
    struct_select.each do |agent|
      @struct_agent_array << struct_agent.new(agent.id, agent.full_name)
    end
    return @struct_agent_array
  end


  def mark_destroy_extext
    approval_extexts.each do |extext|
      extext.mark_for_destruction if extext.value.blank? 
    end
  end

  def set_created_by_extext
    approval_extexts.each do |extext|
      extext.created_by = User.current_user.id unless extext.created_by
    end
  end


  paginates_per 10

  def self.ouput_columns
    return [{name:"approval_identifier"},
            {name:"identifier"},
            {name:"original_title"},
            {name:"four_priority_areas"},
            {name:"document_classification_1"},
            {name:"document_classification_2"},
            {name:"carrier_type"},
            {name:"jmas"},
            {name:"sample_note"},
            {name:"group_approval_result"},
            {name:"group_result_reason"},
            {name:"group_note"},
            {name:"adoption_report_flg"},
            {name:"approval_result"},
            {name:"reason"},
            {name:"approval_end_at"},
            {name:"all_process_end_at"},
            {name:"publishers"},
            {name:"thrsis_review_flg"},
            {name:"ja_text_author_summary_flg"},
            {name:"en_text_author_summary_flg"},
            {name:"proceedings_number_of_year"},
            {name:"excepting_number_of_year"},
            {name:"creators"},
            {name:"country_of_publication"},
            {name:"frequency"},
            {name:"subject"},
            {name:"language"},
            {name:"date_of_publication"},
            {name:"adption_code"},
            {name:"issn"},
            {name:"jstage"}]
  end

end
