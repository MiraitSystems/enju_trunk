module OutputColumns
  # NOTE: resource_import_textfile.excelとの整合性を維持すること
  BOOK_COLUMNS = lambda { %W(
    #{ 'manifestation_type' unless SystemConfiguration.get('manifestations.split_by_type') }
    isbn original_title title_transcription title_alternative carrier_type jpn_or_foreign
    frequency pub_date country_of_publication place_of_publication language
    edition_display_value volume_number_string issue_number_string serial_number_string lccn
    marc_number ndc start_page end_page height width depth price
    acceptance_number access_address repository_content required_role
    except_recent description supplement note creator contributor publisher
    subject accept_type acquired_at_string bookstore library shelf checkout_type
    circulation_status retention_period call_number item_price url
    include_supplements use_restriction item_note rank item_identifier
    remove_reason non_searchable missing_issue del_flg
  ).map{ |c| c unless  c == '' }.compact }
  SERIES_COLUMNS = %w(
    issn original_title title_transcription periodical
    series_statement_identifier note
  )
  ARTICLE_COLUMNS = %w(
    creator original_title title volume_number_string number_of_page pub_date
    call_number access_address subject
  )
  # 出力時の順番に関わるので SERIES_COLUMNS と BOOK_COLUMNS の順番を入れ替えないこと
  ALL_COLUMNS =
    SERIES_COLUMNS.map { |c| "series.#{c}" } + BOOK_COLUMNS.call.map { |c| "book.#{c}" } + ARTICLE_COLUMNS.map {|c| "article.#{c}" }
end
