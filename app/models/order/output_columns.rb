module Order::OutputColumns
  # NOTE: resource_import_textfile.excelとの整合性を維持すること
  BOOK_COLUMNS = lambda { %W(
    group manifestation_identifier order_identifier country_of_publication 
    frequency payment_form transportation_route currency prepayment_principal 
    currency_rate yen_prepayment_principal discount_commision yen_imprest 
    publisher issn pair_manifestation_identifier pair_manifestation_kbn note bookstore adption
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
#  ALL_COLUMNS =
#    SERIES_COLUMNS.map { |c| "series.#{c}" } + BOOK_COLUMNS.call.map { |c| "book.#{c}" } + ARTICLE_COLUMNS.map {|c| "article.#{c}" }
  ALL_COLUMNS =
    BOOK_COLUMNS.call.map { |c| "order.#{c}" }
end
