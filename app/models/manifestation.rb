# -*- encoding: utf-8 -*-
require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'manifestation')
require EnjuTrunkCirculation::Engine.root.join('app', 'models', 'manifestation') # unless SystemConfiguration.isWebOPAC
class Manifestation < ActiveRecord::Base
  self.extend ItemsHelper
  include EnjuNdl::NdlSearch
  include Manifestation::OutputColumns
  has_many :creators, :through => :creates, :source => :agent, :order => :position
  has_many :creators_order_type, :through => :creates, :source => :agent, :order => 'create_type_id, position'
  has_many :contributors, :through => :realizes, :source => :agent, :order => :position
  has_many :contributors_order_type, :through => :realizes, :source => :agent, :order => 'realize_type_id, position'
  has_many :publishers, :through => :produces, :source => :agent, :order => :position
  has_many :publishers_order_type, :through => :produces, :source => :agent, :order => 'produce_type_id, position'
  has_many :work_has_subjects, :foreign_key => 'work_id', :dependent => :destroy
  has_many :subjects, :through => :work_has_subjects, :order => :position
  has_many :reserves, :foreign_key => :manifestation_id, :order => :position
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  has_many :work_has_languages, :foreign_key => 'work_id', :dependent => :destroy
  has_many :languages, :through => :work_has_languages, :order => :position
  belongs_to :carrier_type
  belongs_to :manifestation_type
  has_one :series_has_manifestation, :dependent => :destroy
  has_one :series_statement, :through => :series_has_manifestation
  belongs_to :frequency
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id', :validate => true
  has_one :resource_import_result
  has_many :purchase_requests
  has_many :table_of_contents
  has_many :checked_manifestations
  has_many :theme_has_manifestations, :dependent => :destroy
  has_many :themes, :through => :theme_has_manifestations
  has_many :identifiers
  has_many :manifestation_exinfos, :dependent => :destroy
  has_many :manifestation_extexts, :dependent => :destroy
  has_one :approval

  belongs_to :manifestation_content_type, :class_name => 'ContentType', :foreign_key => 'content_type_id'
  belongs_to :country_of_publication, :class_name => 'Country', :foreign_key => 'country_of_publication_id'

  has_many :work_has_titles, :foreign_key => 'work_id', :order => 'position', :dependent => :destroy
  has_many :manifestation_titles, :through => :work_has_titles
  accepts_nested_attributes_for :work_has_titles
  before_save :mark_destroy_manifestaion_titile

  has_many :orders

  scope :without_master, where(:periodical_master => false)
  JPN_OR_FOREIGN = { I18n.t('jpn_or_foreign.jpn') => 0, I18n.t('jpn_or_foreign.foreign') => 1 }

  SUNSPOT_EAGER_LOADING = {
    include: [
      :creators, :publishers, :contributors, :carrier_type,
      :manifestation_type, :languages, :series_statement,
      :original_manifestations,
      items: :shelf,
      subjects: {classifications: :category},
    ]
  }

  searchable(SUNSPOT_EAGER_LOADING) do
    text :extexts do
      if root_of_series? # 雑誌の場合
        series_manifestations.
          manifestation_extexts.map(&:value).compact if try(:manifestation_extexts).size > 0
      else
        manifestation_extexts.map(&:value).compact if try(:manifestation_extexts).size > 0
      end
    end
    text :fulltext, :contributor, :article_title, :series_title, :exinfo_1, :exinfo_6
    text :title, :default_boost => 2 do
      titles
    end
    text :series_title do
      series_statement.try(:original_title)
    end
    text :spellcheck do
      titles
    end
    text :note do
      if root_of_series? # 雑誌の場合
        series_manifestations.
          map(&:note).compact
      else
        note
      end
    end
    text :description do
      if root_of_series? # 雑誌の場合
        series_manifestations.
          map(&:description).compact
      else
        description
      end
    end
    text :creator do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の著者のリストを取得する
        Agent.joins(:works).joins(:works => :series_statement).
          where(['series_statements.id = ?', self.series_statement.id]).
          collect(&:name).compact
      else
        creator
      end
    end
    text :publisher do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の出版社のリストを取得する
        Agent.joins(:manifestations => :series_statement).
          where(['series_statements.id = ?', self.series_statement.id]).
          collect(&:name).compact
      else
        publisher
      end
    end
    text :subject do
      subjects.collect(&:term) + subjects.collect(&:term_transcription)
    end
    string :title, :multiple => true
    # text フィールドだと区切りのない文字列の index が上手く作成
    #できなかったので。 downcase することにした。
    #他の string 項目も同様の問題があるので、必要な項目は同様の処置が必要。
    string :connect_title do
      title.join('').gsub(/\s/, '').downcase
    end
    string :connect_creator do
      creator.join('').gsub(/\s/, '').downcase
    end
    string :connect_publisher do
      publisher.join('').gsub(/\s/, '').downcase
    end
    string :isbn, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号のISBNのリストを取得する
        series_manifestations.
          map {|manifestation| [manifestation.isbn, manifestation.isbn10, manifestation.wrong_isbn] }.flatten.compact
      else
        [isbn, isbn10, wrong_isbn]
      end
    end
    string :issn, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号のISSNのリストを取得する
        issns = []
        issns << series_statement.try(:issn)
        issns << series_manifestations.
          map(&:issn).compact
        issns.flatten
      else
        [issn, series_statement.try(:issn)]
      end
    end
    string :marc_number
    string :lccn
    string :nbn
    string :subject, :multiple => true do
      subjects.collect(&:term) + subjects.collect(&:term_transcription)
    end
    string :classification, :multiple => true do
      classifications.collect(&:category)
    end
    string :carrier_type do
      carrier_type.name
    end
    string :manifestation_type, :multiple => true do
      manifestation_type.try(:name)
      #if series_statement.try(:id) 
      #  1
      #else
      #  0
      #end
    end
    string :library, :multiple => true do
      items.map{|i| item_library_name(i)}
    end
    string :language, :multiple => true do
      languages.map{|i| item_language_name(i)}
    end
    string :ndc, :multiple => true do
      if root_of_series? # 雑誌の場合
        series_manifestations.map.map(&:ndc).compact
      else
        ndc
      end
    end
    string :item_identifier, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の蔵書の蔵書情報IDのリストを取得する
        series_manifestations_items.
          collect(&:item_identifier).compact
      else
        items.collect(&:item_identifier)
      end
    end
    string :removed_at, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の除籍日のリストを取得する
        series_manifestations_items.
          collect(&:removed_at).compact
      else
        items.collect(&:removed_at)
      end
    end
    boolean :has_removed do
      has_removed?
    end
    boolean :is_article do
      self.article?
    end
    string :shelf, :multiple => true do
      items.collect{|i| "#{item_library_name(i)}_#{i.shelf.name}"}
    end
    string :user, :multiple => true do
    end
    time :created_at
    time :updated_at
    time :deleted_at
    time :date_of_publication
    string :pub_date, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の出版日のリストを取得する
        series_manifestations.
          map(&:date_of_publication).compact
      else
        date_of_publication
      end
    end
    integer :creator_ids, :multiple => true
    integer :contributor_ids, :multiple => true
    integer :publisher_ids, :multiple => true
    integer :item_ids, :multiple => true
    integer :original_manifestation_ids, :multiple => true
    integer :subject_ids, :multiple => true
    integer :required_role_id
    integer :height
    integer :width
    integer :depth
    integer :edition, :multiple => true
    integer :volume_number, :multiple => true
    integer :issue_number, :multiple => true
    integer :serial_number, :multiple => true
    string :edition_display_value, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の出版日のリストを取得する
        series_manifestations.
          map(&:edition_display_value).compact
      else
        edition_display_value
      end
    end
    string :volume_number_string, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の出版日のリストを取得する
        series_manifestations.
          map(&:volume_number_string).compact
      else
        volume_number_string 
      end
    end
    string :issue_number_string, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の出版日のリストを取得する
        series_manifestations.
          map(&:issue_number_string).compact
      else
        issue_number_string 
      end
    end
    string :serial_number_string, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号の出版日のリストを取得する
        series_manifestations.
          map(&:serial_number_string).compact
      else
        serial_number_string 
      end
    end
    string :start_page
    string :end_page
    integer :number_of_pages
    string :number_of_pages, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号のページ数のリストを取得する
        series_manifestations.
          map(&:number_of_pages).compact
      else
        number_of_pages
      end
    end
    float :price
    string :price_string
    boolean :reservable do
      self.reservable?
    end
    boolean :in_process do
      self.in_process?
    end
    integer :series_statement_id do
      series_has_manifestation.try(:series_statement_id)
    end
    boolean :repository_content
    # for OpenURL
    text :aulast do
      creators.map{|creator| creator.last_name}
    end
    text :aufirst do
      creators.map{|creator| creator.first_name}
    end
    # OTC start
    string :creator, :multiple => true do
      creator.map{|au| au.gsub(' ', '')}
    end
    string :contributor, :multiple => true do
      contributor.map{|au| au.gsub(' ', '')}
    end
    string :publisher, :multiple => true do
      publisher.map{|au| au.gsub(' ', '')}
    end
    string :author do
      NKF.nkf('-w --katakana', creators[0].full_name_transcription) if creators[0] and creators[0].full_name_transcription
    end
    text :au do
      creator
    end
    text :atitle do
      title if series_statement.try(:periodical)
    end
    text :btitle do
      title unless series_statement.try(:periodical)
    end
    text :jtitle do
      if root_of_series? # 雑誌の場合
        series_statement.titles
      else                  # 雑誌以外（雑誌の記事も含む）
        original_manifestations.map{|m| m.title}.flatten
      end
    end
    text :isbn do  # 前方一致検索のためtext指定を追加
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号のISBNのリストを取得する
        series_manifestations.
          map {|manifestation| [manifestation.isbn, manifestation.isbn10, manifestation.wrong_isbn] }.flatten.compact
      else
        [isbn, isbn10, wrong_isbn]
      end
    end
    text :issn do  # 前方一致検索のためtext指定を追加
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号のISSNのリストを取得する
        issns = []
        issns << series_statement.try(:issn)
        issns << series_manifestations.
          map(&:issn).compact
        issns.flatten
      else
        [issn, series_statement.try(:issn)]
      end
    end
    text :ndl_jpno do
      # TODO 詳細不明
    end
    string :ndl_dpid do
      # TODO 詳細不明
    end
    # OTC end
    string :sort_title
    boolean :periodical do
      serial?
    end
    boolean :periodical_master
    time :acquired_at
    # 受入最古の所蔵情報を取得するためのSQLを構成する
    # (string :acquired_atでのみ使用する)
    item1 = Item.arel_table
    item2 = item1.alias

    mani1 = Manifestation.arel_table
    mani2 = mani1.alias

    exem1 = Exemplify.arel_table
    exem2 = exem1.alias

    shas1 = SeriesHasManifestation.arel_table
    shas2 = shas1.alias

    acquired_at_subq = item1.
      from(item2).
      project(
        shas2[:manifestation_id].as('grp_manifestation_id'),
        item2[:acquired_at].minimum.as('grp_min_acquired_at')
      ).
      join(exem2).on(
        item2[:id].eq(exem2[:item_id]).
        and(item2[:acquired_at].not_eq(nil))
      ).
      join(mani2).on(
        mani2[:id].eq(exem2[:manifestation_id])
      ).
      join(shas2).on(
        shas2[:manifestation_id].eq(mani2[:id]).
        and(shas2[:series_statement_id].eq(Arel.sql('?')))
      ).
      group(shas2[:manifestation_id]).
      as('t')

    acquired_at_q = item1.
      project(item1['*']).
      join(exem1).on(
        item1[:id].eq(exem1[:item_id]).
        and(item1[:acquired_at].not_eq(nil))
      ).
      join(mani1).on(
        mani1[:id].eq(exem1[:manifestation_id])
      ).
      join(shas1).on(
        shas1[:manifestation_id].eq(mani1[:id]).
        and(shas1[:series_statement_id].eq(Arel.sql('?')))
      ).
      join(acquired_at_subq).on(
        item1[:acquired_at].eq(acquired_at_subq['grp_min_acquired_at']).
        and(mani1[:id].eq(acquired_at_subq['grp_manifestation_id']))
      )
    string :acquired_at, :multiple => true do
      if root_of_series? # 雑誌の場合
        # 同じ雑誌の全号について、それぞれの最古の受入日のリストを取得する
        Item.find_by_sql([acquired_at_q.to_sql, series_statement.id, series_statement.id]).map(&:acquired_at)
      else
        acquired_at
      end
    end
    boolean :except_recent
    boolean :non_searchable do
      non_searchable?
    end
    string :exinfo_1
    string :exinfo_2
    string :exinfo_3
    string :exinfo_4
    string :exinfo_5
    string :exinfo_6
    string :exinfo_7
    string :exinfo_8
    string :exinfo_9
    string :exinfo_10
    text :extext_1
    text :extext_2
    text :extext_3
    text :extext_4
    text :extext_5
    integer :bookbinder_id, :multiple => true do
      items.collect(&:bookbinder_id).compact
    end
    integer :id
    integer :missing_issue
    boolean :circulation_status_in_process do
      true if items.any? {|i| item_circulation_status_name(i) == 'In Process' }
    end
    boolean :circulation_status_in_factory do
      true if items.any? {|i| item_circulation_status_name(i) == 'In Factory' }
    end
  end

  enju_manifestation_viewer
  #enju_amazon
  enju_oai
  #enju_calil_check
  #enju_cinii
  #has_ipaper_and_uses 'Paperclip'
  #enju_scribd
  has_paper_trail
  if Setting.uploaded_file.storage == :s3
    has_attached_file :attachment, :storage => :s3, :s3_credentials => "#{Rails.root.to_s}/config/s3.yml"
  else
    has_attached_file :attachment
  end

  validates_presence_of :carrier_type, :manifestation_type, :country_of_publication
  validates_associated :carrier_type, :languages, :manifestation_type, :country_of_publication
  validates_numericality_of :acceptance_number, :allow_nil => true
  validates_uniqueness_of :nacsis_identifier, :allow_nil => true
  validate :check_rank
  before_validation :set_language, :if => :during_import
  before_validation :uniq_options
  before_validation :set_manifestation_type, :set_country_of_publication
  before_save :set_series_statement

  after_save :index_series_statement
  after_destroy :index_series_statement
  attr_accessor :during_import, :creator, :contributor, :publisher, :subject, :theme, :manifestation_exinfo, :creator_transcription, :publisher_transcription, :contributor_transcription, :subject_transcription

  paginates_per 10

  if defined?(EnjuBookmark)
    has_many :bookmarks, :include => :tags, :dependent => :destroy, :foreign_key => :manifestation_id
    has_many :users, :through => :bookmarks

    searchable do
      string :tag, :multiple => true do
        if root_of_series? # 雑誌の場合
          Bookmark.joins(:manifestation => :series_statement).
            where(['series_statements.id = ?', self.series_statement.id]).
            includes(:tags).
            tag_counts.collect(&:name).compact
        else
          tags.collect(&:name)
        end
      end
      text :tag do
        if root_of_series? # 雑誌の場合
          Bookmark.joins(:manifestation => :series_statement).
            where(['series_statements.id = ?', self.series_statement.id]).
            includes(:tags).
            tag_counts.collect(&:name).compact
        else
          tags.collect(&:name)
        end
      end
    end

    def bookmarked?(user)
      return true if user.bookmarks.where(:url => url).first
      false
    end

    def tags
      if self.bookmarks.first
        self.bookmarks.tag_counts
      else
        []
      end
    end
  end

  def index
    reload if reload_for_index
    solr_index
  end

  def check_rank
    if self.manifestation_type && self.manifestation_type.is_article?
      if self.items and self.items.size > 0
        unless self.items.map{ |item| item.rank.to_i }.compact.include?(0)
          errors[:base] << I18n.t('manifestation.not_has_original')
        end
      end
    end
  end

  def set_language
    self.languages << Language.where(:name => "Japanese").first if self.languages.blank?
  end

  def set_manifestation_type
    self.manifestation_type = ManifestationType.where(:name => 'unknown').first if self.manifestation_type.nil?
  end

  def root_of_series?
    return true if series_statement.try(:root_manifestation_id) == self.id
    false
  end

  def serial?
    if series_statement.try(:periodical) and !periodical_master
      return true unless root_of_series?
    end
    false
  end

  def article?
    self.try(:manifestation_type).try(:is_article?)
  end

  def japanese_article?
    self.try(:manifestation_type).try(:is_japanese_article?)
  end

  def series?
    return true if series_statement
    return false
#    self.try(:manifestation_type).try(:is_series?)
  end

  def non_searchable?
    return false if periodical_master
    return true  if items.empty?
    items.each do |i|
      hide = false
      hide = true if i.non_searchable
      hide = true if item_retention_period_non_searchable?(i)
      if SystemConfiguration.get('manifestation.search.hide_not_for_loan')
        hide = true if i.try(:use_restriction).try(:name) == 'Not For Loan' 
      end
      unless article?
        hide = true if item_circulation_status_unsearchable?(i)
        if SystemConfiguration.get('manifestation.manage_item_rank')
          hide = true if i.rank == 2
        end
      end
      return false unless hide 
    end
    return true
  end

  def has_removed?
    items.each do |i|
      return true if item_circulation_status_name(i) == "Removed" and !i.removed_at.nil?
    end
    false
  end

  def available_checkout_types(user)
    if user
      user.user_group.user_group_has_checkout_types.available_for_carrier_type(self.carrier_type)
    end
  end

  def new_serial?
    return false unless self.serial?    
    return true if self.series_statement.last_issues.include?(self)
#    unless self.serial_number.blank?
#      return true if self == self.series_statement.last_issue
#    else
#      return true if self == self.series_statement.last_issue_with_issue_number
#    end
  end

  def in_basket?(basket)
    basket.manifestations.include?(self)
  end

  def checkout_period(user)
    if available_checkout_types(user)
      available_checkout_types(user).collect(&:checkout_period).max || 0
    end
  end

  def reservation_expired_period(user)
    if available_checkout_types(user)
      available_checkout_types(user).collect(&:reservation_expired_period).max || 0
    end
  end

  def agents
    (creators + contributors + publishers).flatten
  end

  def reservable_with_item?(user = nil)
    if SystemConfiguration.get("reserve.not_reserve_on_loan").nil?
      return true
    end
    if SystemConfiguration.get("reserve.not_reserve_on_loan")
      if user.try(:has_role?, 'Librarian')
        return true
      end
      if items.index {|item| item.available_for_reserve_with_config? }
        return true
      else
        return false
      end
    end
    return true
  end

  def reservable?
    unless SystemConfiguration.get("reserves.able_for_not_item")
      return false if items.for_checkout.empty? 
    end
    return false if self.periodical_master?
    true
  end

  def in_process?
    return true if items.map{ |i| i.shelf.try(:open_access)}.include?(9)
    false
  end

  def checkouts(start_date, end_date)
    Checkout.completed(start_date, end_date).where(:item_id => self.items.collect(&:id))
  end

  def creator(reload = false)
    creators(reload).collect(&:name).flatten
  end

  def contributor
    contributors.collect(&:name).flatten
  end

  def publisher(reload = false)
    publishers(reload).collect(&:name).flatten
  end

  # TODO: よりよい推薦方法
  def self.pickup(keyword = nil)
    return nil if self.cached_numdocs < 5
    manifestation = nil
    # TODO: ヒット件数が0件のキーワードがあるときに指摘する
    response = Manifestation.search(:include => [:creators, :contributors, :publishers, :subjects, :items]) do
      fulltext keyword if keyword
      order_by(:random)
      paginate :page => 1, :per_page => 1
    end
    manifestation = response.results.first
  end

  def extract_text
    return nil unless attachment.path
    # TODO: S3 support
    response = `curl "#{Sunspot.config.solr.url}/update/extract?&extractOnly=true&wt=ruby" --data-binary @#{attachment.path} -H "Content-type:text/html"`
    self.fulltext = eval(response)[""]
    save(:validate => false)
  end

  def created(agent)
    creates.where(:agent_id => agent.id).first
  end

  def realized(agent)
    realizes.where(:agent_id => agent.id).first
  end

  def produced(agent)
    produces.where(:agent_id => agent.id).first
  end

  def sort_title
    NKF.nkf('-w --katakana', title_transcription) if title_transcription
  end

  def classifications
    subjects.collect(&:classifications).flatten
  end

  def questions(options = {})
    id = self.id
    options = {:page => 1, :per_page => Question.per_page}.merge(options)
    page = options[:page]
    per_page = options[:per_page]
    user = options[:user]
    Question.search do
      with(:manifestation_id).equal_to id
      any_of do
        unless user.try(:has_role?, 'Librarian')
          with(:shared).equal_to true
        #  with(:username).equal_to user.try(:username)
        end
      end
      paginate :page => page, :per_page => per_page
    end.results
  end

  def web_item
    items.where(:shelf_id => Shelf.web.id).first
  end

  def index_series_statement
    series_statement.try(:index)
  end

  def set_series_statement
    if self.series_statement_id
      series_statement = SeriesStatement.find(self.series_statement_id)
      self.series_statement = series_statement unless series_statement.blank?   
    end
  end 
 
  def uniq_options
    self.creators.uniq!
    self.contributors.uniq!
    self.publishers.uniq!
    self.subjects.uniq!
  end

  def set_country_of_publication
    self.country_of_publication = Country.where(:name => 'Japan').first || Country.find(1) if self.country_of_publication.blank?
  end

  def last_checkout_datetime
    Manifestation.find(:last, :include => [:items, :items => :checkouts], :conditions => {:manifestations => {:id => self.id}}, :order => 'items.created_at DESC').items.first.checkouts.first.created_at rescue nil
  end

  def reserve_count(type)
    sum = 0
    case type
    when nil
    when :all
      sum = Reserve.where(:manifestation_id=>self.id).count
    when :previous_term
      term = Term.previous_term
      if term
        sum = Reserve.where("manifestation_id = ? AND created_at >= ? AND created_at <= ?", self.id, term.start_at, term.end_at).count 
      end
    when :current_term
      term = Term.current_term
      if term
        sum = Reserve.where("manifestation_id = ? AND created_at >= ? AND created_at <= ?", self.id, term.start_at, term.end_at).count 
      end
    end
    return sum
  end

  def checkout_count(type)
    sum = 0
    case type
    when nil
    when :all
      self.items.all.each {|item| sum += Checkout.where(:item_id=>item.id).count} 
    when :previous_term
      term = Term.previous_term
      if term
        self.items.all.each {|item| sum += Checkout.where("item_id = ? AND created_at >= ? AND created_at <= ?", item.id, term.start_at, term.end_at).count }
      end
    when :current_term
      term = Term.current_term
      if term
        self.items.all.each {|item| sum += Checkout.where("item_id = ? AND created_at >= ? AND created_at <= ?", item.id, term.start_at, term.end_at).count } 
      end
    end
    return sum
  end

  def next_item_for_retain(lib)
    items = self.items_ordered_for_retain(lib)
    items.each do |item|
      return item if item.available_for_checkout? && item.circulation_status != CirculationStatus.find(:first, :conditions => ["name = ?", 'Available For Pickup'])
    end
    return nil
  end

  def items_ordered_for_retain(lib = nil)
    if lib.nil?
      items = self.items
    else
      items = self.items.for_retain_from_own(lib).concat(self.items.for_retain_from_others(lib)).flatten
    end
  end
 
  def ordered?
    self.purchase_requests.each do |p|
#      return true if p.state == "ordered"
      return true if ["ordered", "accepted", "pending"].include?(p.state)
    end
    return false
  end

  def add_subject(terms)
    terms.to_s.split(';').each do |s|
      s = s.to_s.exstrip_with_full_size_space
      subject = Subject.where(:term => s).first
      unless subject
        subject = Subject.create(:term => s, :subject_type_id => 1)
      end
      self.subjects << subject unless self.subjects.include?(subject)
    end
  end

  def self.build_search_for_manifestations_list(search, query, with_filter, without_filter)
    search.build do
      fulltext query unless query.blank?
      with_filter.each do |field, op, value|
        with(field).__send__(op, value)
      end
      without_filter.each do |field, op, value|
        without(field).__send__(op, value)
      end
    end

    search
  end

  # 要求された書式で書誌リストを生成する。
  # 生成結果を構造体で返す。構造体がoutputのとき:
  #
  #  output.result_type: 生成結果のタイプ
  #    :data: データそのもの
  #    :path: データを書き込んだファイルのパス名
  #    :delayed: 後で処理する
  #  output.data: 生成結果のデータ(result_typeが:dataのとき)
  #  output.path: 生成結果のパス名(result_typeが:pathのとき)
  #  output.job_name: 後で処理する際のジョブ名(result_typeが:delayedのとき)
  def self.generate_manifestation_list(solr_search, output_type, current_user, search_condition_summary, cols=[], threshold = nil, &block)
    solr_search.build {
      paginate :page => 1, :per_page => Manifestation.count
    }

    get_total = proc do
      series_statements_total =
        Manifestation.where(:id => solr_search.execute.raw_results.map(&:primary_key)).joins(:series_statement => :manifestations).count
    end
    
    get_all_ids = proc do
      solr_search.execute.raw_results.map(&:primary_key)
    end


    threshold ||= Setting.background_job.threshold.export rescue nil
    if threshold && threshold > 0 && get_total.call > threshold
      # 指定件数以上のときにはバックグラウンドジョブにする。
      user_file = UserFile.new(current_user)

      io, info = user_file.create(:manifestation_list_prepare, 'manifestation_list_prepare.tmp')
      begin
        Marshal.dump(get_all_ids.call, io)
      ensure
        io.close
      end

      job_name = GenerateManifestationListJob.generate_job_name
      Delayed::Job.enqueue GenerateManifestationListJob.new(job_name, info, output_type, current_user, search_condition_summary, cols)
      output = OpenStruct.new
      output.result_type = :delayed
      output.job_name = job_name
      block.call(output)
      return
    end
    manifestation_ids = get_all_ids.call
    generate_manifestation_list_internal(manifestation_ids, output_type, current_user, search_condition_summary, cols, &block)
  end

  # TODO: エクセル、TSV、PDF利用部分のメソッド名を修正すること	
  def self.generate_manifestation_list_internal(manifestation_ids, output_type, current_user, summary, cols, &block)
    output = OpenStruct.new
    output.result_type = output_type == :excelx ? :path : :data
    case output_type
    when :pdf 
      method = 'get_manifestation_list_pdf'
      type  = cols.first =~ /\Aarticle./ ? :article : :book
      result = output.__send__("#{output.result_type}=", 
        self.__send__(method, manifestation_ids, current_user, summary, type))
    when :request
      method = 'get_missing_list_pdf'
      result = output.__send__("#{output.result_type}=", 
        self.__send__(method, manifestation_ids, current_user))
    when :excelx, :tsv
      method = 'get_manifestation_list_excelx'
      if output_type == :tsv
        result = output.__send__("#{output.result_type}=",
          self.__send__('get_manifestation_list_tsv_csv', manifestation_ids, cols))
      else
        result = output.__send__("#{output.result_type}=", 
          self.__send__('get_manifestation_list_excelx', manifestation_ids, current_user, cols))
      end
    when :label
      method = 'get_label_list_tsv_csv'
      result = output.__send__("#{output.result_type}=", 
        self.__send__(method, manifestation_ids))
    end

    if output_type == :label
      if SystemConfiguration.get("set_output_format_type")
        output.filename = Setting.manifestation_label_list_print_tsv.filename
      else
        output.filename = Setting.manifestation_label_list_print_csv.filename
      end
    elsif output_type == :tsv
      if SystemConfiguration.get("set_output_format_type")
        output.filename = Setting.manifestation_list_print_tsv.filename
      else
        output.filename = Setting.manifestation_list_print_csv.filename
      end
    else
      filename_method = method.sub(/\Aget_(.*)(_[^_]+)\z/) { "#{$1}_print#{$2}" }
      output.filename = Setting.__send__(filename_method).filename
    end

    if output.result_type == :path
      output.path, output.data = result
    else
      output.data = /_pdf\z/ =~ method ? result.generate : result
    end
    block.call(output)
  end

  def self.struct_theme_selects
    struct_theme = Struct.new(:id, :text)
    @struct_theme_array = []
    struct_select = Theme.all
    struct_select.each do |theme|
      @struct_theme_array << struct_theme.new(theme.id, theme.name)
    end
    return @struct_theme_array
  end
 
  def self.get_manifestation_list_excelx(manifestation_ids, current_user, selected_column = [])
    user_file = UserFile.new(current_user)
    excel_filepath, excel_fileinfo = user_file.create(:manifestation_list, Setting.manifestation_list_print_excelx.filename)

    begin
      require 'axlsx_hack'
      ws_cls = Axlsx::AppendOnlyWorksheet
    rescue LoadError
      require 'axlsx'
      ws_cls = Axlsx::Worksheet
    end
    pkg = Axlsx::Package.new
    wb = pkg.workbook
    sty = wb.styles.add_style :font_name => Setting.manifestation_list_print_excelx.fontname
    sheet_name = {
      'book'    => 'book_list',
      'series'  => 'series_list',
      'article' => 'article_list',
    }
    worksheet = {}
    style = {}
    # ヘッダー部分
    column = self.set_column(selected_column)
    column.keys.each do |type|
      if column[type].blank?
        column.delete(type); next
      end
      worksheet[type] = ws_cls.new(wb, :name => sheet_name[type]).tap do |sheet|
        row = column[type].map { |(t, c)| I18n.t("resource_import_textfile.excel.#{t}.#{c}") }
        style[type] = [sty]*row.size
        sheet.add_row row, :types => :string, :style => style[type]
      end
    end
    # データ部分
    self.set_manifestations_data(:excelx, column, manifestation_ids, worksheet, style)
    pkg.serialize(excel_filepath)
    return [excel_filepath, excel_fileinfo]
  end

  def self.get_manifestation_list_tsv_csv(manifestation_ids, selected_column = [])
    split = SystemConfiguration.get("set_output_format_type") ? "\t" : ","
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8")
    # ヘッダー部分
    column = self.set_column(selected_column)
    column.keys.each do |type|
      if column[type].blank?
        column.delete(type); next
      end
    end
    type = column.keys.include?('article') ? 'article' : 'series'
    row = column[type].map { |(t, c)| I18n.t("resource_import_textfile.excel.#{t}.#{c}") }
    data << '"' + row.join(%Q[\"#{split}\"]) +"\"\n"
    # データ部分
    self.set_manifestations_data(:tsv_csv, column, manifestation_ids, data)

    return data
  end

  def self.get_label_list_tsv_csv(manifestation_ids)
    split = SystemConfiguration.get("set_output_format_type") ? "\t" : ","
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8")

    where(:id => manifestation_ids).includes(:items => [:shelf]).find_in_batches do |manifestations|
      manifestations.each do |manifestation|
        manifestation.items.each do |item|
          row = []
          row << item.manifestation.ndc
          row << item.manifestation.manifestation_exinfos(:name => 'author_mark').first.try(:value)# 著者記号
          row << item.shelf.name 
          data << row.join(split) +"\n" 
        end
      end       
    end
    return data
  end

  def self.set_column(selected_column = [])
    column = {
      'book'    => [], # 一般書誌(manifestation_type.is_{series,article}?がfalse
      'series'  => [], # 雑誌(manifestation_type.is_series?がtrue)
      'article' => [], # 文献(manifestation_type.is_article?がtrue)
    }
    selected_column.each do |type_col|
#      next unless ALL_COLUMNS.include?(type_col) #TODO
      next unless /\A([^.]+)\.([^.]+)\.*([^.]+)*([^.]+)\z/ =~ type_col
      val = $2
      val += ".#{$3}" if $3
      val += $4 if $4
      column[$1]       << [$1, val]
      column['series'] << [$1, val] if $1 == 'book' # NOTE: 雑誌の行は雑誌向けカラム+一般書誌向けカラム(参照: resource_import_textfile.excel)
    end
    return column
  end

  def self.set_manifestations_data(format_type, column, manifestation_ids, data, style = {})
    logger.debug "begin export manifestations"
    transaction do
      where(:id => manifestation_ids).
          includes(
            :carrier_type, :languages, :required_role,
            :frequency, :creators, :contributors,
            :publishers, :subjects, :manifestation_type,
            :series_statement,
            :items => [
              :bookstore, :checkout_type,
              :circulation_status, :required_role,
              :accept_type, :retention_period,
              :use_restriction,
              :shelf => :library,
            ]
          ).
          find_in_batches do |manifestations|
        logger.debug "begin a batch set"
        manifestations.each do |manifestation|
          if SystemConfiguration.get('manifestations.split_by_type') and manifestation.article?
            type = 'article'
            target = [manifestation]
          elsif manifestation.series?
            type = 'series'
            # target = manifestation.series_statement.manifestations
            # XXX: 検索結果由来とseries_statement由来とでmanifestationレコードに重複が生じる可能性があることに注意(32b51f2c以前のコード>をそのまま残した)
            # TODO:重複はさせない
             if manifestation.periodical_master
               #target = manifestation.series_statement.manifestaitions
               target = manifestation.series_statement.manifestations.map{ |m| m unless m.periodical_master }.compact
             else
               target = [manifestation]
             end
          else # 一般書誌
            type = 'book'
            target = [manifestation]
          end

          # 出力すべきカラムがない場合はスキップ
          next if column[type].blank?
          target.each do |m|
            if m.items.blank?
              items = [nil]
            else
              items = m.items
            end
            items.each do |i|
              row = []
              column[type].each do |(t, c)|
                row << m.excel_worksheet_value(t, c, i)
              end
              if format_type == :excelx
                data[type].add_row row, :types => :string, :style => style[type]
              else
                split = SystemConfiguration.get("set_output_format_type") ? "\t" : ","
                SERIES_COLUMNS.size.times { data << '""' + split } unless m.series?
                data << '"' + row.join(%Q[\"#{split}\"]) +"\"\n"
              end

              if Setting.export.delete_article
                # 文献をエクスポート時にはその文献情報を削除する
                # copied from app/models/resource_import_textresult.rb:92-98
                if i && type == 'article' && m.article?
                  if i.reserve
                    i.reserve.revert_request rescue nil
                  end
                  i.destroy
                end
              end
            end

            if Setting.export.delete_article
              # 文献をエクスポート時にはその文献情報を削除する
              # copied from app/models/resource_import_textresult.rb:102-105
              if type == 'article' && m.article?
                manifestation.destroy if manifestation.items.count == 0
              end
            end
          end # target.each
        end # manifestations.each
        logger.debug "end a batch set"
      end # find_in_batches
    end # transaction
    logger.debug "end export manifestations"
  end

  # XLSX形式でのエクスポートのための値を生成する
  # ws_type: ワークシートの種別
  # ws_col: ワークシートでのカラム名
  # item: 対象とするItemレコード
  def excel_worksheet_value(ws_type, ws_col, item = nil)
    helper = Object.new
    helper.extend(ManifestationsHelper)
    val = nil

    case ws_col
    #when 'manifestation_type'
    #  val = manifestation_type.try(:display_name) || ''

    when 'original_title', 'title_transcription', 'series_statement_identifier', 'periodical', 'issn', 'note'
      if ws_type == 'series'
        val = series_statement.excel_worksheet_value(ws_type, ws_col)
      end

    when 'title'
      if ws_type == 'article'
        val = article_title.to_s
      end

    when 'url'
      if ws_type == 'article'
        val = access_address.to_s
      end

    when 'volume_number_string'
      if ws_type == 'article' &&
          volume_number_string.present? && issue_number_string.present?
        val = "#{volume_number_string}*#{issue_number_string}"
      elsif volume_number_string.present?
        val = volume_number_string.to_s
      else
        val = ''
      end

    when 'number_of_page'
      if start_page.present? && end_page.present?
        val = "#{start_page}-#{end_page}"
      elsif start_page
        val = start_page.to_s
      else
        val = ''
      end

    when 'carrier_type', 'required_role', 'manifestation_type', 'country_of_publication'
      val = __send__(ws_col).try(:name) || ''

    when 'frequency'
      val = __send__(ws_col).try(:display_name) || ''

    when 'creator', 'contributor', 'publisher'
      sep = ';'
      if ws_col == 'creator' &&
          ws_type == 'article' && !japanese_article?
        sep = ' '
      end
      val = __send__("#{ws_col}s").map(&:full_name).join(sep)
      if ws_col == 'creator' &&
          ws_type == 'article' && japanese_article? && !val.blank?
        val += sep
      end

    when 'subject'
      sep = ';'
      if ws_type == 'article' && !japanese_article?
        sep = '*'
      end
      val = __send__(:subjects).map(&:term).join(sep)

    when 'language'
      sep = ';'
      if ws_type == 'article' && !japanese_article?
        sep = '*'
      end
      val = __send__(:languages).map(&:name).join(sep)

    when 'missing_issue'
      val = helper.missing_status(missing_issue) || ''

    when 'del_flg'
      val = '' # モデルには格納されない情報

    else
      splits = ws_col.split('.')
      case splits[0]
      when 'manifestation_extext'
        extext = ManifestationExtext.where(name: splits[1], manifestation_id: __send__(:id)).first 
        val =  extext.value if extext
      when 'manifestation_exinfo'
        exinfo = ManifestationExinfo.where(name: splits[1], manifestation_id: __send__(:id)).first
        val =  exinfo.value if exinfo
      end
    end
    return val unless val.nil?

    # その他の項目はitemまたはmanifestationの
    # 同名属性からそのまま転記する

    if item
      if /\Aitem_/ =~ ws_col
        begin
          val = item.excel_worksheet_value(ws_type, $') || ''
        rescue NoMethodError
        end
      end

      if val.nil?
        if ws_col != 'note' and ws_col != 'price' and ws_col != 'price_string'
          begin
            val = item.excel_worksheet_value(ws_type, ws_col) || ''
          rescue NoMethodError
          end
        end
      end
    end

    if val.nil?
      begin
        val = __send__(ws_col) || ''
      rescue NoMethodError
        val = ''
      end
    end
    val

  end

  def self.get_missing_list_pdf(manifestation_ids, current_user)
    where(:id => manifestation_ids).find_in_batches do |manifestations|
      manifestations.each do |manifestation|
        manifestation.missing_issue = 2 unless manifestation.missing_issue == 3
        manifestation.save!(:validate => false)
      end
    end
    return get_manifestation_list_pdf(manifestation_ids, current_user)
  end

  def self.get_manifestation_list_pdf(manifestation_ids, current_user, summary = nil, type = :book)
    report = ThinReports::Report.new :layout => File.join(Rails.root, 'report', 'searchlist.tlf')

    # set page_num
    report.events.on :page_create do |e|
      e.page.item(:page).value(e.page.no)
    end
    report.events.on :generate do |e|
      e.pages.each do |page|
        page.item(:total).value(e.report.page_count)
      end
    end
    # set data
    report.start_new_page do |page|
      page.item(:date).value(Time.now)
      page.item(:query).value(summary)

      where(:id => manifestation_ids).find_in_batches do |manifestations|
        manifestations.each do |manifestation|
          if type == :book
             next if manifestation.article?
          else
             next unless manifestation.article?
          end
          page.list(:list).add_row do |row|
            # modified data format
            item_identifiers = manifestation.items.map{ |item| item.item_identifier }
            creator = manifestation.creators.readable_by(current_user).map{ |agent| agent.full_name }
            contributor = manifestation.contributors.readable_by(current_user).map{ |agent| agent.full_name }
            publisher = manifestation.publishers.readable_by(current_user).map{ |agent| agent.full_name }
            reserves = Reserve.waiting.where(:manifestation_id => manifestation.id, :checked_out_at => nil)
            # set list
            row.item(:title).value(manifestation.original_title)
            if type == :book
              row.item(:item_identifier).value(item_identifiers.join(',')) unless item_identifiers.empty?
            end
            row.item(:creator).value(creator.join(',')) unless creator.empty?
            row.item(:contributor).value(contributor.join(',')) unless contributor.empty?
            row.item(:publisher).value(publisher.join(',')) unless publisher.empty?
            row.item(:pub_date).value(manifestation.pub_date)
          end
        end
      end
    end
    return report
  end

  def self.get_manifestation_locate(manifestation, current_user)
    report = ThinReports::Report.new :layout => File.join(Rails.root, 'report', 'manifestation_reseat.tlf')
   
    # footer
    report.layout.config.list(:list) do
      use_stores :total => 0
      events.on :footer_insert do |e|
        e.section.item(:date).value(Time.now.strftime('%Y/%m/%d %H:%M'))
      end
    end
    # main
    report.start_new_page do |page|
      # set manifestation_information
      7.times { |i|
        label, data = "", ""
        page.list(:list).add_row do |row|
          case i
          when 0
            label = I18n.t('activerecord.attributes.manifestation.original_title')
            data  = manifestation.original_title
          when 1
            label = I18n.t('agent.creator')
            data  = manifestation.creators.readable_by(current_user).map{|agent| agent.full_name}
            data  = data.join(",")
          when 2
            label = I18n.t('agent.publisher')
            data  = manifestation.publishers.readable_by(current_user).map{|agent| agent.full_name}
            data  = data.join(",")
          when 3
            label = I18n.t('activerecord.attributes.manifestation.price')
            data  = manifestation.price
          when 4
            label = I18n.t('activerecord.attributes.manifestation.page')
            data  = manifestation.number_of_pages.to_s + 'p' if manifestation.number_of_pages
          when 5
            label = I18n.t('activerecord.attributes.manifestation.size')
            data  = manifestation.height.to_s + 'cm' if manifestation.height
          when 6
            label = I18n.t('activerecord.attributes.series_statement.original_title')
            data  = manifestation.series_statement.original_title if manifestation.series_statement
          when 7
            label = I18n.t('activerecord.attributes.manifestation.isbn')
            data  = manifestation.isbn
          end
          row.item(:label).show
          row.item(:data).show
          row.item(:dot_line).hide
          row.item(:label).value(label.to_s + ":")
          row.item(:data).value(data)
        end
      }

      # set item_information
      manifestation.items.each do |item|
        if SystemConfiguration.get('manifestation.manage_item_rank')
          if current_user.nil? or !current_user.has_role?('Librarian')
            next unless item.rank <= 1
            next if item.retention_period.non_searchable
            next if item.circulation_status.name == "Removed"
            next if item.non_searchable
          end
        end
        6.times { |i|
          label, data = "", ""
          page.list(:list).add_row do |row|
            row.item(:label).show
            row.item(:data).show
            row.item(:dot_line).hide
            case i
            when 0
              row.item(:label).hide
              row.item(:data).hide
              row.item(:dot_line).show
            when 1
              label = I18n.t('activerecord.models.library')
              data  = item.shelf.library.display_name.localize
            when 2
              label = I18n.t('activerecord.models.shelf')
              data  = item.shelf.display_name.localize
            when 3
              label = I18n.t('activerecord.attributes.item.call_number')
              data  = call_numberformat(item)
            when 4
              label = I18n.t('activerecord.attributes.item.item_identifier')
              data  = item.item_identifier
            when 5
              label = I18n.t('activerecord.models.circulation_status')
              data  = item.circulation_status.display_name.localize
            end
            row.item(:label).value(label.to_s + ":")
            row.item(:data).value(data)
          end
        }
      end
    end
    return report 
  end

  class << self
    # 指定されたNCIDによりNACSIS-CAT検索を行い、
    # 得られた情報からManifestationを作成する。
    #
    # * ncid - NCID
    # * book_types - 書籍の書誌種別(ManifestationType)の配列(NOTE: バッチ時の外部キャッシュ用で和書・洋書にあたるレコードを与える)
    def create_from_ncid(ncid, book_types = ManifestationType.book.all)
      raise ArgumentError if ncid.blank?
      created_manifestations = []

      #子書誌情報の登録
      result = NacsisCat.search(dbs: [:book], id: ncid)
      attrs_result = new_from_nacsis_cat(ncid, result[:book].first, book_types)
      created_manifestations << create(attrs_result[:attributes])

      #親書誌情報の登録
      attrs_result[:parents].each do |ptbl_record|
        parent_manifestation = where(:nacsis_identifier => ptbl_record['PTBID']).first
        if parent_manifestation
          created_manifestations << parent_manifestation
        else
          parent_result = NacsisCat.search(dbs: [:book], id: ptbl_record['PTBID'])
          if parent_result[:book].blank?
            unless ptbl_record['PTBTR'].nil?
              created_manifestations << where(:original_title => ptbl_record['PTBTR']).first_or_create do |m|
                if m.new_record?
                  m.nacsis_identifier = ptbl_record['PTBID']
                  m.title_transcription = ptbl_record['PTBTRR']
                  m.title_alternative_transcription = ptbl_record['PTBTRVR']
                  m.note = ptbl_record['PTBNO']
                end
              end
            end
          else
            parent_attrs_result = new_from_nacsis_cat(ptbl_record['PTBID'], parent_result[:book].first, book_types)
            created_manifestations << create(parent_attrs_result[:attributes])
          end
        end
      end

      #親書誌関係の登録
      created_manifestations.reverse.each do |parent|
        created_manifestations.each do |child|
          break if parent == child
          parent.derived_manifestations << child
        end
      end

      created_manifestations
    end

    # 指定されたNCIDリストによりNACSIS-CAT検索を行い、
    # 得られた情報からManifestationを作成する。
    #
    # * ncids - NCIDのリスト
    # * opts
    #   * book_types - 書籍の書誌種別(ManifestationType)の配列(NOTE: バッチ時の外部キャッシュ用で和書・洋書にあたるレコードを与える)
    #   * nacsis_batch_size - 一度に検索するNCID数
    def batch_create_from_ncid(ncids, opts = {}, &block)
      nacsis_batch_size = opts[:nacsis_batch_size] || 50
      book_types = opts[:book_types] || ManifestationType.book.all

      ncids.each_slice(nacsis_batch_size) do |ids|
        result = NacsisCat.search(dbs: [:book], id: ids)
        result[:book].each do |nacsis_cat|
          record = new_from_nacsis_cat(nacsis_cat.ncid, nacsis_cat, book_types)
          record.save
          block.call(record) if block
        end
      end
    end

    private

      def new_from_nacsis_cat(ncid, nacsis_cat, book_types)
        attrs = {
          nacsis_identifier: ncid,
        }
        if nacsis_cat.present?
          nacsis_info = nacsis_cat.detail
          attrs[:external_catalog] = 2
          attrs[:original_title] = nacsis_info[:subject_heading]
          attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
          attrs[:title_alternative] = nacsis_info[:title_alternative].try(:join,",")
          attrs[:title_alternative_transcription] = nacsis_info[:title_alternative_transcription].try(:join, ",")
          attrs[:place_of_publication] = nacsis_info[:publication_place].try(:join, ",")
          attrs[:note] = nacsis_info[:note]
          attrs[:marc_number] = nacsis_info[:marc]
          attrs[:pub_date] = nacsis_info[:publish_year]
          attrs[:size] = nacsis_info[:size]

          # NDCは最新のバージョンのものを検索して設定する。
          attrs[:ndc] = search_clasification(nacsis_info[:cls_info], "NDC")

          # 出版国がnilの場合、unknownを設定する。
          if nacsis_info[:pub_country]
            attrs[:country_of_publication] = nacsis_info[:pub_country]
          else
            attrs[:country_of_publication] = Country.where(:name => 'unknown').first
          end

          # 和書または洋書を設定し、同時に言語も設定する。
          # テキストの言語がnilの場合、未分類、不明を設定する。
          attrs[:languages] = []
          if nacsis_info[:text_language]
            if nacsis_info[:text_language].name == 'Japanese'
              attrs[:manifestation_type] = book_types.detect {|bt| /japanese/io =~ bt.name }
            else
              attrs[:manifestation_type] = book_types.detect {|bt| /foreign/io =~ bt.name }
            end
            attrs[:languages] << nacsis_info[:text_language]
          else
            attrs[:manifestation_type] = book_types.detect {|bt| "unknown" == bt.name }
            attrs[:languages] << Language.where(:iso_639_3 => 'unknown').first
          end

          # 関連テーブル：著者の設定
          attrs[:creators] = []
          nacsis_info[:creators].each do |creator|
            #TODO 著者名典拠IDが存在する場合、nacsisの著者名典拠DBからデータを取得する。
            attrs[:creators] <<
              Agent.where(:full_name => creator['AHDNG'].to_s).first_or_create do |p|
                if p.new_record?
                  p.agent_identifier = creator['AID']
                  p.full_name_transcription = creator['AHDNGR']
                  p.full_name_alternative_transcription = creator['AHDNGVR']
                end
              end
          end

          # 関連テーブル：出版者の設定
          attrs[:publishers] = []
          nacsis_info[:publishers].each do |pub|
            attrs[:publishers] << Agent.where(:full_name => pub.to_s).first_or_create
          end

          # 関連テーブル：件名の設定
          attrs[:subjects] = []
          nacsis_info[:subjects].each do |subject|
            subject_type = SubjectType.where(:name => subject['SHK']).first
            subject_type = SubjectType.where(:name => 'K').first if subject_type.nil?
            if subject['SHD'].present? && subject_type
              sub = Subject.where(["term = ? and subject_type_id = ?", subject['SHD'].to_s, subject_type.id]).first
              if sub
                attrs[:subjects] << sub
              else
                attrs[:subjects] << Subject.create(:term => subject['SHD'],
                                                   :term_transcription => subject['SHR'],
                                                   :subject_type_id => subject_type.id)
              end
            end
          end

          # 関連テーブル：ISBNの設定
          identifier_type = IdentifierType.where(:name => 'isbn').first
          if identifier_type
            attrs[:identifiers] = []
            nacsis_info[:vol_info].each do |vol_info|
              attrs[:identifiers] << Identifier.create(:body => vol_info['ISBN'], :identifier_type_id => identifier_type.id) if vol_info['ISBN']
            end
          end

          # 親書誌の設定
          parents = nacsis_info[:ptb_info]

        end

        {:attributes => attrs, :parents => parents}
      end

      def search_clasification(cls_hash, key)
        return nil if cls_hash.blank? or key.blank?
        if key == "NDC"
          ["NDC9","NDC8","NDC7","NDC6","NDC"].each do |ndc|
            return cls_hash[ndc] if cls_hash[ndc].present?
          end
        else
          return cls_hash[key]
        end
      end
  end

  class GenerateManifestationListJob
    include Rails.application.routes.url_helpers
    include BackgroundJobUtils

    def initialize(name, fileinfo, output_type, user, search_condition_summary, cols)
      @name = name
      @fileinfo = fileinfo
      @output_type = output_type
      @user = user
      @search_condition_summary = search_condition_summary
      @cols = cols
    end
    attr_accessor :name, :fileinfo, :output_type, :user, :search_condition_summary, :cols

    def perform
      user_file = UserFile.new(user)
      path, = user_file.find(fileinfo[:category], fileinfo[:filename], fileinfo[:random])
      manifestation_ids = open(path, 'r') {|io| Marshal.load(io) }

      Manifestation.generate_manifestation_list_internal(manifestation_ids, output_type, user, search_condition_summary, cols) do |output|
        io, info = user_file.create(:manifestation_list, output.filename)
        if output.result_type == :path
          open(output.path) {|io2| FileUtils.copy_stream(io2, io) }
        else
          io.print output.data
        end
        io.close

        url = my_account_url(:filename => info[:filename], :category => info[:category], :random => info[:random])
        message(
          user,
          I18n.t('manifestation.output_job_success_subject', :job_name => name),
          I18n.t('manifestation.output_job_success_body', :job_name => name, :url => url))
      end

    rescue => exception
      message(
        user,
        I18n.t('manifestation.output_job_error_subject', :job_name => name),
        #I18n.t('manifestation.output_job_error_body', :job_name => name, :message => exception.message))
        I18n.t('manifestation.output_job_error_body', :job_name => name, :message => exception.message+exception.backtrace))
    end
  end

  private

    INTERNAL_ITEM_ATTR_CACHE = {}
    def internal_item_attr_cache
      if INTERNAL_ITEM_ATTR_CACHE[:limit] &&
          INTERNAL_ITEM_ATTR_CACHE[:limit] > Time.now
        return INTERNAL_ITEM_ATTR_CACHE
      end

      self.class.init_internal_item_attr_cache!
      INTERNAL_ITEM_ATTR_CACHE
    end

    def item_attr_with_cache(attr_key, attr_id)
      cache = internal_item_attr_cache
      if cache[attr_key].include?(attr_id)
        return cache[attr_key][attr_id]
      end
      cache[attr_key][attr_id] = yield
    end

    def item_attr_without_cache(attr_key, attr_id)
      yield
    end

    def self.init_internal_item_attr_cache!
      INTERNAL_ITEM_ATTR_CACHE.clear
      INTERNAL_ITEM_ATTR_CACHE[:limit] = Time.now + 60*60*24
      INTERNAL_ITEM_ATTR_CACHE[:rp_non_searchable] = {}
      INTERNAL_ITEM_ATTR_CACHE[:cs_unsearchable] = {}
      INTERNAL_ITEM_ATTR_CACHE[:cs_name] = {}
      INTERNAL_ITEM_ATTR_CACHE[:library_name] = {}
    end

    def self.enable_item_attr_cache!
      alias_method :item_attr, :item_attr_with_cache
      define_method(:reload_for_index) { false }
      init_internal_item_attr_cache!
      logger.info 'Internal item attributions cache for Manifestation is enabled.'
    end

    def self.disable_item_attr_cache!
      alias_method :item_attr, :item_attr_without_cache
      define_method(:reload_for_index) { true }
      init_internal_item_attr_cache!
      logger.info 'Internal item attributions cache for Manifestation is disabled.'
    end

    if ENV['ENABLE_ITEM_ATTR_CACHE']
      enable_item_attr_cache!
    else
      disable_item_attr_cache!
    end

    def item_retention_period_non_searchable?(item)
      item_attr(:rp_non_searchable, item.retention_period_id) do
        item.retention_period.try(:non_searchable)
      end
    end

    def item_circulation_status_unsearchable?(item)
      item_attr(:cs_name, item.circulation_status_id) do
        item.circulation_status.try(:unsearchable)
      end
    end

    def item_circulation_status_name(item)
      item_attr(:cs_unsearchable, item.circulation_status_id) do
        item.circulation_status.try(:name)
      end
    end

    def item_library_name(item)
      item_attr(:library_name, item.shelf.library_id) do
        item.shelf.library.name
      end
    end

    def item_language_name(item)
      item_attr(:language_name, item.id) do
        item.name
      end
    end

    def series_manifestations
      if !reload_for_index &&
          @_series_manifestations_cache
        @_series_manifestations_cache
      end

      @_series_manifestations_cache =
        Manifestation.joins(:series_statement).
          where(['series_statements.id = ?', self.series_statement.id])
    end

    def series_manifestations_items
      if !reload_for_index &&
          @_series_manifestations_items_cache
        @_series_manifestations_items_cache
      end

      @_series_manifestations_items_cache =
        Item.joins(:manifestation => :series_statement).
          where(['series_statements.id = ?', self.series_statement.id])
    end

    def mark_destroy_manifestaion_titile
      work_has_titles.each do |title|
        if title.manifestation_title.title.blank?
          Title.destroy([title.title_id])
          title.mark_for_destruction
        end
      end
    end

end

# == Schema Information
#
# Table name: manifestations
#
#  id                              :integer         not null, primary key
#  original_title                  :text            not null
#  title_alternative               :text
#  title_transcription             :text
#  classification_number           :string(255)
#  identifier                      :string(255)
#  date_of_publication             :datetime
#  date_copyrighted                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  deleted_at                      :datetime
#  access_address                  :string(255)
#  language_id                     :integer         default(1), not null
#  carrier_type_id                 :integer         default(1), not null
#  extent_id                       :integer         default(1), not null
#  start_page                      :integer
#  end_page                        :integer
#  height                          :decimal(, )
#  width                           :decimal(, )
#  depth                           :decimal(, )
#  isbn                            :string(255)
#  isbn10                          :string(255)
#  wrong_isbn                      :string(255)
#  nbn                             :string(255)
#  lccn                            :string(255)
#  oclc_number                     :string(255)
#  issn                            :string(255)
#  price                           :integer
#  fulltext                        :text
#  volume_number_string              :string(255)
#  issue_number_string               :string(255)
#  serial_number_string              :string(255)
#  edition                         :integer
#  note                            :text
#  produces_count                  :integer         default(0), not null
#  exemplifies_count               :integer         default(0), not null
#  embodies_count                  :integer         default(0), not null
#  work_has_subjects_count         :integer         default(0), not null
#  repository_content              :boolean         default(FALSE), not null
#  lock_version                    :integer         default(0), not null
#  required_role_id                :integer         default(1), not null
#  state                           :string(255)
#  required_score                  :integer         default(0), not null
#  frequency_id                    :integer         default(1), not null
#  subscription_master             :boolean         default(FALSE), not null
#  ipaper_id                       :integer
#  ipaper_access_key               :string(255)
#  attachment_file_name            :string(255)
#  attachment_content_type         :string(255)
#  attachment_file_size            :integer
#  attachment_updated_at           :datetime
#  nii_type_id                     :integer
#  title_alternative_transcription :text
#  description                     :text
#  abstract                        :text
#  available_at                    :datetime
#  valid_until                     :datetime
#  date_submitted                  :datetime
#  date_accepted                   :datetime
#  date_caputured                  :datetime
#  file_hash                       :string(255)
#  pub_date                        :string(255)
#  periodical_master               :boolean         default(FALSE), not null
#

