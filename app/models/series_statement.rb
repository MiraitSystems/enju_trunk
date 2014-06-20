# -*- encoding: utf-8 -*-
class SeriesStatement < ActiveRecord::Base
  attr_accessible :original_title, :numbering, :title_subseries,
    :numbering_subseries, :title_transcription, :title_alternative,
    :series_statement_identifier, :issn, :periodical, :note,
    :title_subseries_transcription, :relationship_family_id, :nacsis_series_statementid, :sequence_pattern_id,
    :publication_status_id

  has_many :series_has_manifestations
  has_many :manifestations, :through => :series_has_manifestations
  belongs_to :sequence_pattern
  belongs_to :root_manifestation, :foreign_key => :root_manifestation_id, :class_name => 'Manifestation'
  belongs_to :relationship_family
  belongs_to :publication_status
  validates_presence_of :original_title
  validate :check_issn
  #after_create :create_initial_manifestation

  has_paper_trail

  acts_as_list
  searchable do
    text :title do
      original_title
    end
    text :numbering, :title_subseries, :numbering_subseries, :issn, :series_statement_identifier
    integer :manifestation_ids, :multiple => true do
      manifestations.collect(&:id)
    end
    integer :position
    boolean :periodical
  end

  normalize_attributes :original_title, :issn

  paginates_per 10

  # TODO: 不要メソッド　テストを実行し、削除しても問題内容であれば消すこと
  def last_issue
    m = manifestations.where('periodical_master IS FALSE AND serial_number IS NOT NULL').order('serial_number DESC').first # || manifestations.first
    m = manifestations.where('periodical_master IS FALSE AND date_of_publication IS NOT NULL').order('date_of_publication DESC').first || manifestations.first unless m
    return m
  end

  def last_issues
    return [] unless self.periodical
    issues = []
    serial_number = manifestations.where('serial_number IS NOT NULL').select(:serial_number).order('serial_number DESC').first.try(:serial_number)
    if serial_number
      issues = manifestations.where("serial_number =#{serial_number}") 
    else
      volume_number = manifestations.where('volume_number IS NOT NULL').select(:volume_number).order('volume_number DESC').first.try(:volume_number)
      if volume_number
        issue_number = manifestations.where("volume_number = #{volume_number} AND issue_number IS NOT NULL").select(:issue_number).order('issue_number DESC').first.try(:issue_number)
        if issue_number
          issues = manifestations.where("volume_number = #{volume_number} AND issue_number = #{issue_number}")
        else
          issues = manifestations.where("volume_number = #{volume_number}")
        end
      else
        issue_number = manifestations.where('issue_number IS NOT NULL').select(:issue_number).order('issue_number DESC').first.try(:issue_number)
        issues = manifestations.where("issue_number = #{issue_number}") if issue_number
      end
    end 
    return issues
  end

  def last_issue_with_issue_number
    return nil unless self.periodical
    manifestations.where('issue_number IS NOT NULL').order('volume_number DESC').order('issue_number DESC').first # || manifestations.first
  end

  def self.latest_issues
    manifestations = []
    series_statements = SeriesStatement.all
    series_statements.each do |series|
      if series.last_issues
        series.last_issues.each do |s|  
          manifestations << s
        end
      end
    #  manifestations << series.last_issue if series.last_issue
    end
    return manifestations
  end

  def check_issn
#    self.issn = ISBN_Tools.cleanup(issn)
    if issn.present?
      unless StdNum::ISSN.valid?(issn)
        errors.add(:issn)
      end
    end
  end

  def create_initial_manifestation
    return nil if initial_manifestation
    return nil unless periodical
    manifestation = Manifestation.new(
      :original_title => original_title
    )
    manifestation.periodical_master = true
    self.manifestations << manifestation
  end

  def initial_manifestation
    manifestations.where(:periodical_master => true).first
  end

  def first_issue
    manifestations.without_master.order(:date_of_publication).first
  end

  def latest_issue
    manifestations.without_master.order(:date_of_publication).last
  end

  def manifestation_included(manifestation)
    series_has_manifestations.where(:manifestation_id => manifestation.id).first
  end

  def titles
    titles = [
      original_title,
      title_transcription,
      manifestations.map { |manifestation| [manifestation.original_title, manifestation.title_transcription] }
    ]
    if relationship_family
      titles << relationship_family.series_statements.map{ |series_statement| [series_statement.original_title, series_statement.title_transcription] }
    end
    titles.flatten.compact
  end

  def new_manifestation
    manifestation = Manifestation.new
    manifestation.original_title = self.original_title
    manifestation.title_transcription = self.title_transcription
    manifestation.issn = self.issn
    if root_manifestation = self.root_manifestation
      manifestation.creates = root_manifestation.creates.order(:position)
      manifestation.realizes = root_manifestation.realizes.order(:position)
      manifestation.produces = root_manifestation.produces.order(:position)
      manifestation.carrier_type = root_manifestation.carrier_type
      manifestation.manifestation_type = root_manifestation.manifestation_type
      manifestation.frequency = root_manifestation.frequency
      manifestation.country_of_publication = root_manifestation.country_of_publication
      manifestation.place_of_publication = root_manifestation.place_of_publication
      manifestation.access_address = root_manifestation.access_address
      manifestation.required_role = root_manifestation.required_role
      manifestation.work_has_languages = root_manifestation.work_has_languages
      manifestation.manifestation_identifier = root_manifestation.identifier
      manifestation.manifestation_has_classifications = root_manifestation.manifestation_has_classifications.order(:position)
      manifestation.subjects = root_manifestation.subjects.order(:position)
    end  
    manifestation.series_statement = self
    return manifestation
  end

  def initialize_root_manifestation(manifestation = nil)
    manifestation ||= build_root_manifestation
    manifestation.periodical_master   = true
    manifestation.periodical          = self.periodical || false
    manifestation.original_title      = self.original_title
    manifestation.title_transcription = self.title_transcription
    manifestation.title_alternative   = self.title_alternative
    manifestation
  end

  def self.create_root_manifestation(series_statement, objs)
    root_manifestation = series_statement.root_manifestation
    root_manifestation = series_statement.initialize_root_manifestation(root_manifestation)
    root_manifestation.save!

    root_manifestation.subjects = objs[:subjects]
    root_manifestation.creates = objs[:creates]
    root_manifestation.realizes = objs[:realizes]
    root_manifestation.produces = objs[:produces]
    root_manifestation.manifestation_exinfos = ManifestationExinfo.
      add_exinfos(objs[:exinfos], root_manifestation.id) if objs[:exinfos]
    root_manifestation.manifestation_extexts = ManifestationExtext.
      add_extexts(objs[:extexts], root_manifestation.id) if objs[:extexts]
    return root_manifestation
  end

  # XLSX形式でのエクスポートのための値を生成する
  # ws_type: ワークシートの種別
  # ws_col: ワークシートでのカラム名
  # sep_flg: 分割指定(ONのときture)
  # ccount: 分割指定OKのときのカラム数
  def excel_worksheet_value(ws_type, ws_col, sep_flg, ccount)
    val = nil

    case ws_col
    when 'periodical'
      val = (periodical || false).to_s
    else
      val = __send__(ws_col) || ''
    end

    val
  end

end

# == Schema Information
#
# Table name: series_statements
#
#  id                          :integer         not null, primary key
#  original_title              :text
#  numbering                   :text
#  title_subseries             :text
#  numbering_subseries         :text
#  position                    :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  title_transcription         :text
#  title_alternative           :text
#  series_statement_identifier :string(255)
#  issn                        :string(255)
#  periodical                  :boolean
#

