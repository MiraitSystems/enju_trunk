# -*- encoding: utf-8 -*-
class SeriesStatement < ActiveRecord::Base
  attr_accessible :original_title, :numbering, :title_subseries,
    :numbering_subseries, :title_transcription, :title_alternative,
    :series_statement_identifier, :issn, :periodical, :note,
    :title_subseries_transcription, :relationship_family_id, :nacsis_series_statementid

  has_many :series_has_manifestations
  has_many :manifestations, :through => :series_has_manifestations
  belongs_to :root_manifestation, :foreign_key => :root_manifestation_id, :class_name => 'Manifestation'
  belongs_to :relationship_family
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
    manifestations.where('serial_number IS NOT NULL').order('serial_number DESC').first # || manifestations.first
    manifestations.where('date_of_publication IS NOT NULL').order('date_of_publication DESC').first || manifestations.first
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

  # XLSX形式でのエクスポートのための値を生成する
  # ws_type: ワークシートの種別
  # ws_col: ワークシートでのカラム名
  def excel_worksheet_value(ws_type, ws_col)
    val = nil

    case ws_col
    when 'periodical'
      val = (periodical || false).to_s
    else
      val = __send__(ws_col) || ''
    end

    val
  end

  class << self

    # 指定されたNCIDによりNACSIS-CAT検索を行い、
    # 得られた情報からSeriesStatementを作成する。
    #
    # * ncid - NCID
    # * book_types - 書籍の書誌種別(ManifestationType)の配列
    #                (NOTE: バッチ時の外部キャッシュ用で和雑誌・洋雑誌にあたるレコードを与える)
    # * nacsis_cat - NacsisCat.searchを既に実行している場合、取得したNacsisCatモデルを設定する
    def create_series_statement_from_ncid(ncid, book_types = ManifestationType.series.all, nacsis_cat = nil)
      raise ArgumentError if ncid.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:serial], id: ncid)
        nacsis_cat = result[:serial].first
      end
      create_series_from_nacsis_cat(nacsis_cat.detail, book_types)
    end

    private

      def create_series_from_nacsis_cat(nacsis_info, book_types)
        return nil if nacsis_info.blank? || book_types.blank?

        # 元の雑誌情報作成
        series_statement = create_series_statement_from_nacsis_cat(nacsis_info, book_types)

        # 遍歴ファミリーの作成
        relationship_family = create_family_from_nacsis_cat(nacsis_info)

        if relationship_family
          # 元の雑誌をファミリーに紐づける
          relationship_family.series_statements = []
          relationship_family.series_statements << series_statement

          nacsis_info[:bhn_info].each do |bhn|
            result_bhn = NacsisCat.search(dbs: [:serial], id: bhn['BHBID'])
            nacsis_info_bhn = result_bhn[:serial].first.try(:detail)

            # 遍歴の雑誌情報作成
            series_statement_bhn = SeriesStatement.where(:nacsis_series_statementid => nacsis_info_bhn[:ncid]).first
            if series_statement_bhn.nil?
              series_statement_bhn = create_series_statement_from_nacsis_cat(nacsis_info_bhn, book_types)
            end

            # 雑誌同士の関連情報作成
            series_statement_relationship = SeriesStatementRelationship.new(:seq => 1, :source => 1)
            if check_relationship_before?(bhn['BHK'].to_s)
              series_statement_relationship.before_series_statement_relationship = series_statement_bhn
              series_statement_relationship.after_series_statement_relationship = series_statement
            else
              series_statement_relationship.before_series_statement_relationship = series_statement
              series_statement_relationship.after_series_statement_relationship = series_statement_bhn
            end
            series_statement_relationship.series_statement_relationship_type = get_relationship_type(bhn['BHK'].to_s)
            series_statement_relationship.relationship_family = relationship_family
            series_statement_relationship.save!

            # 遍歴ファミリーに遍歴の雑誌情報を関連付ける
            relationship_family.series_statements << series_statement_bhn
          end
        end
        series_statement
      end

      def create_series_statement_from_nacsis_cat(nacsis_info, book_types)
        return nil if nacsis_info.blank? || book_types.blank?
        series_statement = SeriesStatement.where(:nacsis_series_statementid => nacsis_info[:ncid]).first
        if series_statement.nil?
          series_attrs = new_series_statement_from_nacsis_cat(nacsis_info)
          series_statement = new(series_attrs)
          root_attrs = new_root_from_nacsis_cat(nacsis_info, book_types)
          series_statement.root_manifestation = Manifestation.new(root_attrs)
          series_statement.root_manifestation.periodical_master = true
          series_statement.root_manifestation.save!
          series_statement.manifestations << series_statement.root_manifestation
          series_statement.save!
        end
        series_statement
      end

      def new_series_statement_from_nacsis_cat(nacsis_info)
        return {} if nacsis_info.blank?
        attrs = {}
        attrs[:nacsis_series_statementid] = nacsis_info[:ncid]
        attrs[:periodical] = true
        attrs[:original_title] = nacsis_info[:subject_heading]
        attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
        attrs[:title_alternative] = nacsis_info[:title_alternative].try(:join,",")
        attrs[:issn] = nacsis_info[:issn]
        attrs[:note] = nacsis_info[:note]
        attrs
      end

      def new_root_from_nacsis_cat(nacsis_info, book_types)
        return {} if nacsis_info.blank? || book_types.blank?
        attrs = {}
        attrs[:nacsis_identifier] = nacsis_info[:ncid]
        attrs[:external_catalog] = 2
        attrs[:original_title] = nacsis_info[:subject_heading]
        attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
        attrs[:title_alternative] = nacsis_info[:title_alternative].try(:join,",")
        attrs[:title_alternative_transcription] = nacsis_info[:title_alternative_transcription].try(:join, ",")
        attrs[:place_of_publication] = nacsis_info[:publication_place].try(:join, ",")
        attrs[:note] = nacsis_info[:note]
        attrs[:marc_number] = nacsis_info[:marc]
        attrs[:date_of_publication_string] = nacsis_info[:publish_year]
        attrs[:size] = nacsis_info[:size]
        attrs[:lccn] = nacsis_info[:lccn]
        attrs[:price_string] = nacsis_info[:price]

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
        attrs
      end

      def create_family_from_nacsis_cat(nacsis_info)
        return nil if nacsis_info.blank? || nacsis_info[:fid].nil?
        RelationshipFamily.where(:fid => nacsis_info[:fid]).first_or_create do |rf|
          rf.display_name = "CHANGE_#{nacsis_info[:fid]}" if rf.new_record?
        end
      end

      def get_relationship_type(type_str)
        return nil if type_str.nil?
        case type_str[0, 1]
        when 'C' # 継続
          SeriesStatementRelationshipType.where(:typeid => '1').first
        when 'A' # 吸収
          SeriesStatementRelationshipType.where(:typeid => '2').first
        when 'S' # 派生
          SeriesStatementRelationshipType.where(:typeid => '3').first
        else     # 未登録
          SeriesStatementRelationshipType.where(:typeid => '30').first
        end
      end

      def check_relationship_before?(type_str)
        return nil if type_str.nil?
        if type_str[1, 1] == 'F' # 前誌
          true
        else # 後誌
          false
        end
      end
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

