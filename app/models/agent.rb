# -*- encoding: utf-8 -*-
class Agent < ActiveRecord::Base
  attr_accessible :last_name, :middle_name, :first_name,
    :last_name_transcription, :middle_name_transcription,
    :first_name_transcription, :corporate_name, :corporate_name_transcription,
    :full_name, :full_name_transcription, :full_name_alternative, :zip_code_1,
    :zip_code_2, :address_1, :address_2, :address_1_note, :address_2_note,
    :telephone_number_1, :telephone_number_2, :fax_number_1, :fax_number_2,
    :other_designation, :place, :street, :locality, :region, :language_id,
    :country_id, :agent_type_id, :note, :required_role_id, :email, :email_2, :url,
    :full_name_alternative_transcription, :title, :birth_date, :death_date,
    :agent_identifier,
    :telephone_number_1_type_id, :extelephone_number_1,
    :extelephone_number_1_type_id, :fax_number_1_type_id,
    :telephone_number_2_type_id, :extelephone_number_2,
    :extelephone_number_2_type_id, :fax_number_2_type_id, :user_username,
    :exclude_state, :keyperson_1, :keyperson_2, :corporate_type_id, :place_id,
    :grade_id, :gender_id

  scope :readable_by, lambda{|user| {:conditions => ['required_role_id <= ?', user.try(:user_has_role).try(:role_id) || Role.where(:name => 'Guest').select(:id).first.id]}}
  has_many :creates, :dependent => :destroy
  has_many :works, :through => :creates
  has_many :realizes, :dependent => :destroy
  has_many :expressions, :through => :realizes
  has_many :produces, :dependent => :destroy
  has_many :manifestations, :through => :produces
  has_many :children, :foreign_key => 'parent_id', :class_name => 'AgentRelationship', :dependent => :destroy
  has_many :parents, :foreign_key => 'child_id', :class_name => 'AgentRelationship', :dependent => :destroy
  has_many :derived_agents, :through => :children, :source => :child
  has_many :original_agents, :through => :parents, :source => :parent
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  has_many :donates #TODO :dependent => :destroy が無いため、agentを削除や統合した場合、レコードが残る
  has_many :donated_items, :through => :donates, :source => :item
  has_many :owns, :dependent => :destroy
  has_many :items, :through => :owns
  has_many :agent_merges, :dependent => :destroy
  has_many :agent_merge_lists, :through => :agent_merges
  has_many :agent_aliases, :dependent => :destroy
  belongs_to :user
  belongs_to :agent_type
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id', :validate => true
  belongs_to :language
  belongs_to :country
  belongs_to :place, :class_name => 'Subject', :foreign_key => 'place_id'
  belongs_to :corporate_type, :class_name => 'Keycode', :foreign_key => 'corporate_type_id'
  belongs_to :gender, :class_name => 'Keycode', :foreign_key => 'gender_id'
  belongs_to :grade, :class_name => 'Keycode', :foreign_key => 'grade_id'
		
  has_one :agent_import_result

  has_many :orders

  accepts_nested_attributes_for :agent_aliases
  attr_accessible :agent_aliases_attributes

  validates_presence_of :language, :agent_type, :country
  validates_associated :language, :agent_type, :country
  validates :full_name, :presence => true, :length => {:maximum => 255}
  validates :user_id, :uniqueness => true, :allow_nil => true
  validates :birth_date, :format => {:with => /^\d+(-\d{0,2}){0,2}$/}, :allow_blank => true
  validates :death_date, :format => {:with => /^\d+(-\d{0,2}){0,2}$/}, :allow_blank => true
  validates :email, :format => {:with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i}, :allow_blank => true
  validates :email_2, :format => {:with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i}, :allow_blank => true
  validate :check_birth_date
#  validate :check_full_name
  before_validation :set_role_and_name, :set_date_of_birth, :set_date_of_death
  before_save :change_note, :mark_destroy_blank_full_name

  validate :check_duplicate_user

  has_paper_trail
  attr_accessor :user_username
  #[:address_1, :address_2].each do |column|
  #  encrypt_with_public_key column,
  #    :key_pair => File.join(Rails.root.to_s,'config','keypair.pem'),
  #    :base64 => true
  #end

  searchable do
    text :name, :place, :address_1, :address_2, :other_designation, :note
    string :last_name
    string :first_name
    string :last_name_transcription
    string :first_name_transcription 
    string :full_name
    string :full_name_transcription
    string :full_name_alternative
    string :telephone_number_1 
    string :telephone_number_2
    string :extelephone_number_1 
    string :extelephone_number_2
    string :fax_number_1 
    string :fax_number_2
    string :zip_code_1
    string :zip_code_2
    string :place
    string :address_1
    string :address_2
    string :other_designation
    string :note
    string :username do
      user.username if user
    end
    string :agent_type do
      agent_type.name
    end
    time :created_at
    time :updated_at
    time :date_of_birth
    time :date_of_death
    string :user
    integer :work_ids, :multiple => true
    integer :expression_ids, :multiple => true
    integer :manifestation_ids, :multiple => true
    integer :agent_merge_list_ids, :multiple => true
    integer :derived_agent_ids, :multiple => true
    integer :original_agent_ids, :multiple => true
    integer :required_role_id
    integer :agent_type_id
    integer :user_id
    integer :exclude_state
    integer :id
    AgentRelationshipType.pluck(:id).each do |type_id|
      integer 'relationship_type_parent_' + type_id.to_s , :multiple => true do
        parents.select_type_id(type_id).pluck(:parent_id)
      end
      integer 'relationship_type_child_' + type_id.to_s , :multiple => true do
        children.select_type_id(type_id).pluck(:child_id)
      end
    end if AgentRelationshipType.table_exists?
  end

  paginates_per 10

  def mark_destroy_blank_full_name
    agent_aliases.each do |agent_alias|
      agent_alias.mark_for_destruction if agent_alias.full_name.blank? and agent_alias.full_name_transcription.blank? and agent_alias.full_name_alternative.blank?
    end
  end

  def full_name_without_space
    full_name.gsub(/\s/, "")
  end

  def set_role_and_name
    self.required_role = Role.where(:name => 'Librarian').first if self.required_role_id.nil?
    set_full_name
  end

  def set_full_name
    #puts "@@@"
    #puts self
    #puts "@@@"

    if self.full_name.blank?
      if self.last_name.to_s.strip and self.first_name.to_s.strip and SystemConfiguration.get("family_name_first") == true
        self.full_name = [last_name, middle_name, first_name].compact.join(" ").to_s.strip
      else
        self.full_name = [first_name, last_name, middle_name].compact.join(" ").to_s.strip
      end
    end
    if self.full_name_transcription.blank?
      self.full_name_transcription = [last_name_transcription, middle_name_transcription, first_name_transcription].join(" ").to_s.strip
    end
    [self.full_name, self.full_name_transcription]
  end

  def set_date_of_birth
    if birth_date.blank?
			date = nil
		else
			begin
				date = Time.zone.parse("#{birth_date}")
			rescue ArgumentError
				begin
					date = Time.zone.parse("#{birth_date}-01")
				rescue ArgumentError
					begin
						date = Time.zone.parse("#{birth_date}-01-01")
					rescue
						nil
					end
				end
			end
		end

    self.date_of_birth = date
  end

  def set_date_of_death
    if death_date.blank?
			date = nil
		else
			begin
				date = Time.zone.parse("#{death_date}")
			rescue ArgumentError
				begin
					date = Time.zone.parse("#{death_date}-01")
				rescue ArgumentError
					begin
						date = Time.zone.parse("#{death_date}-01-01")
					rescue
						nil
					end
				end
			end
		end

    self.date_of_death = date
  end

  def check_birth_date
    if date_of_birth.present? and date_of_death.present?
      if date_of_birth > date_of_death
        errors.add(:birth_date)
        errors.add(:death_date)
      end
    end
  end

  def check_full_name
    return unless full_name
    return if user
    agents = Agent.where("full_name = ? AND user_id IS NULL", full_name)
    errors.add(:full_name, I18n.t('errors.messages.taken')) unless agents.blank?
  end

  #def full_name_generate
  #  # TODO: 日本人以外は？
  #  name = []
  #  name << self.last_name.to_s.strip
  #  name << self.middle_name.to_s.strip unless self.middle_name.blank?
  #  name << self.first_name.to_s.strip
  #  name << self.corporate_name.to_s.strip
  #  name.join(" ").strip
  #end

  def full_name_without_space
    full_name.gsub(/\s/, "")
  #  # TODO: 日本人以外は？
  #  name = []
  #  name << self.last_name.to_s.strip
  #  name << self.middle_name.to_s.strip
  #  name << self.first_name.to_s.strip
  #  name << self.corporate_name.to_s.strip
  #  name.join("").strip
  end

  def full_name_transcription_without_space
    full_name_transcription.to_s.gsub(/\s/, "")
  end

  def full_name_alternative_without_space
    full_name_alternative.to_s.gsub(/\s/, "")
  end

  def name
    name = []
    name << full_name.to_s.strip
    name << full_name_transcription.to_s.strip
    name << full_name_alternative.to_s.strip
    #name << full_name_without_space
    #name << full_name_transcription_without_space
    #name << full_name_alternative_without_space
    #name << full_name.wakati rescue nil
    #name << full_name_transcription.wakati rescue nil
    #name << full_name_alternative.wakati rescue nil
    name
  end

  def date
    if date_of_birth
      if date_of_death
        "#{date_of_birth} - #{date_of_death}"
      else
        "#{date_of_birth} -"
      end
    end
  end

  def creator?(resource)
    resource.creators.include?(self)
  end

  def publisher?(resource)
    resource.publishers.include?(self)
  end

  def check_required_role(user)
    return true if self.user.blank?
    return true if self.user.required_role.name == 'Guest'
    return true if user == self.user
    return true if user.has_role?(self.user.required_role.name)
    false
  rescue NoMethodError
    false
  end

  def created(work)
    creates.where(:work_id => work.id).first
  end

  def realized(expression)
    realizes.where(:expression_id => expression.id).first
  end

  def produced(manifestation)
    produces.where(:manifestation_id => manifestation.id).first
  end

  def owned(item)
    owns.where(:item_id => item.id)
  end

  def self.import_agents(agent_lists, options = {})
    list = []
    return list if agent_lists.blank?

    options[:language_id] ||= 1

    agent_lists.uniq.compact.each do |attrs|
      agent = add_agent(attrs[:full_name], attrs[:full_name_transcription], options)
      next if agent.blank?
      list << agent if agent
    end
    list
  end

  def self.add_agents(agent_names, agent_transcriptions = nil, options = {})
    return [] if agent_names.blank?
    names = agent_names.gsub('；', ';').split(/;/)
    if agent_transcriptions.nil?
      transcriptions = []
    elsif agent_transcriptions == ''
      transcriptions = ['']
    else
      transcriptions = agent_transcriptions.gsub('；', ';').split(/;/, -names.size)
    end
    list = []
    names.compact.each_with_index do |name, i|
      agent = add_agent(name, transcriptions[i], options)
      next if agent.blank?
      list << agent
    end
    list.uniq
  end

  # options:
  #   :create_new: 新規作成をするかどうかの指定(デフォルトはtrue)
  #   その他: 新規作成時の属性値(更新には使用されない)
  def self.add_agent(name, transcription = nil, options = {})
    if options.include?(:create_new)
      create_new = options.delete(:create_new)
    else
      create_new = true # 特に指定がなければ新規作成もする
    end

    name = name.try(:exstrip_with_full_size_space)
    return {} if name.blank?

    agent = Agent.where(full_name: name).first
    transcription = transcription.try(:exstrip_with_full_size_space)
    if agent.blank? && create_new
      agent = Agent.new(options.merge(full_name: name))
      agent.full_name_transcription = transcription if transcription
      exclude_agents = SystemConfiguration.get("exclude_agents").split(',').map {|word| word.gsub(/^[　\s]*(.*?)[　\s]*$/, '\1') }
      agent.exclude_state = 1 if exclude_agents.include?(name)
      agent.save
    else
      if transcription
        agent.full_name_transcription = transcription
        agent.save
      end
    end
    agent
  end

  def agents
    self.original_agents + self.derived_agents
  end

  def self.create_with_user(params, user)
    agent = Agent.new(params)
    #agent.full_name = user.username if agent.full_name.blank?
    agent.email = user.email
    agent.required_role = Role.find(:first, :conditions => ['name=?', "Librarian"]) rescue nil
    agent.language = Language.find(:first, :conditions => ['iso_639_1=?', user.locale]) rescue nil
    agent
  end

  def change_note
    data = Agent.find(self.id).note rescue nil
    unless data == self.note
      self.note_update_at = Time.zone.now
      if User.current_user.nil?
        #TODO
        self.note_update_by = "SYSTEM"
        self.note_update_library = "SYSTEM"
      else
        self.note_update_by = User.current_user.agent.full_name
        self.note_update_library = Library.find(User.current_user.library_id).display_name
      end
    end
  end

  private
  def check_duplicate_user
    return if SystemConfiguration.get("agent.check_duplicate_user").nil? || SystemConfiguration.get("agent.check_duplicate_user") == false
    return if self.full_name_transcription.blank? or self.birth_date.blank? or self.telephone_number_1.blank?
    chash = {}
    chash[:full_name_transcription] = self.full_name_transcription.strip
    chash[:birth_date] = self.birth_date
    chash[:telephone_number_1] = self.telephone_number_1
    agents = Agent.find(:all, :conditions => chash)
    agents.delete_if { |p| p.id == self.id } 
    if self.new_record? 
      errors.add(:base, I18n.t('agent.duplicate_user')) if agents.size > 0
    end
    #logger.info errors.inspect
  end
end

# == Schema Information
#
# Table name: agents
#
#  id                                  :integer         not null, primary key
#  user_id                             :integer
#  last_name                           :string(255)
#  middle_name                         :string(255)
#  first_name                          :string(255)
#  last_name_transcription             :string(255)
#  middle_name_transcription           :string(255)
#  first_name_transcription            :string(255)
#  corporate_name                      :string(255)
#  corporate_name_transcription        :string(255)
#  full_name                           :string(255)
#  full_name_transcription             :text
#  full_name_alternative               :text
#  created_at                          :datetime
#  updated_at                          :datetime
#  deleted_at                          :datetime
#  zip_code_1                          :string(255)
#  zip_code_2                          :string(255)
#  address_1                           :text
#  address_2                           :text
#  address_1_note                      :text
#  address_2_note                      :text
#  telephone_number_1                  :string(255)
#  telephone_number_2                  :string(255)
#  fax_number_1                        :string(255)
#  fax_number_2                        :string(255)
#  other_designation                   :text
#  place                               :text
#  street                              :text
#  locality                            :text
#  region                              :text
#  date_of_birth                       :datetime
#  date_of_death                       :datetime
#  language_id                         :integer         default(1), not null
#  country_id                          :integer         default(1), not null
#  agent_type_id                      :integer         default(1), not null
#  lock_version                        :integer         default(0), not null
#  note                                :text
#  creates_count                       :integer         default(0), not null
#  realizes_count                      :integer         default(0), not null
#  produces_count                      :integer         default(0), not null
#  owns_count                          :integer         default(0), not null
#  required_role_id                    :integer         default(1), not null
#  required_score                      :integer         default(0), not null
#  state                               :string(255)
#  email                               :text
#  url                                 :text
#  full_name_alternative_transcription :text
#  title                               :string(255)
#  birth_date                          :string(255)
#  death_date                          :string(255)
#  address_1_key                       :binary
#  address_1_iv                        :binary
#  address_2_key                       :binary
#  address_2_iv                        :binary
#  telephone_number_key                :binary
#  telephone_number_iv                 :binary
#

