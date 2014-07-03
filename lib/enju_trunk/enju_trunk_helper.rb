# coding: utf-8

module EnjuTrunk
  module EnjuTrunkHelper
    extend ActiveSupport::Concern

    included do
      include PictureFilesHelper
      include EnjuBookJacket::BookJacketHelper if defined?(EnjuBookJacket)
      include EnjuManifestationViewer::ManifestationViewerHelper if defined?(EnjuManifestationViewer)
      include EnjuBookmark::BookmarkHelper if defined?(EnjuBookmark)
      include JaDateFormat
      include EnjuTerminalsHelper
    end

    def form_icon(carrier_type)
      case carrier_type.name
      when 'print'
        image_tag('icons/book.png', :size => '16x16', :alt => carrier_type.display_name.localize, :title => carrier_type.display_name.localize)
      when 'CD'
        image_tag('icons/cd.png', :size => '16x16', :alt => carrier_type.display_name.localize, :title => carrier_type.display_name.localize)
      when 'DVD'
        image_tag('icons/dvd.png', :size => '16x16', :alt => carrier_type.display_name.localize, :title => carrier_type.display_name.localize)
      when 'file'
        image_tag('icons/monitor.png', :size => '16x16', :alt => carrier_type.display_name.localize, :title => carrier_type.display_name.localize)
      else
        image_tag('icons/help.png', :size => '16x16', :alt => 'unknown', :title => 'unknown')
      end
    rescue NoMethodError
      image_tag('icons/help.png', :size => '16x16', :alt => 'unknown', :title => 'unknown')
    end

    def content_type_icon(content_type)
      case content_type.name
      when 'text'
        image_tag('icons/page_white_text.png', :size => '16x16', :alt => content_type.display_name.localize, :title => content_type.display_name.localize)
      when 'picture'
        image_tag('icons/picture.png', :size => '16x16', :alt => content_type.display_name.localize, :title => content_type.display_name.localize)
      when 'sound'
        image_tag('icons/sound.png', :size => '16x16', :alt => content_type.display_name.localize, :title => content_type.display_name.localize)
      when 'video'
        image_tag('icons/film.png', :size => '16x16', :alt => content_type.display_name.localize, :title => content_type.display_name.localize)
      else
        image_tag('icons/help.png', :size => '16x16', :alt => ('unknown'), :title => 'unknown')
      end
    rescue NoMethodError
      image_tag('icons/help.png', :size => '16x16', :alt => ('unknown'), :title => 'unknown')
    end

    def agent_type_icon(agent_type)
      case agent_type
      when 'Person'
        image_tag('icons/user.png', :size => '16x16', :alt => ('Person'), :title => ('Person'))
      when 'CorporateBody'
        image_tag('icons/group.png', :size => '16x16', :alt => ('CorporateBody'), :title => ('CorporateBody'))
      else
        image_tag('icons/help.png', :size => '16x16', :alt => ('unknown'), :title => ('unknown'))
      end
    end

    def link_to_tag(tag)
      link_to tag, manifestations_path(:tag => tag.name)
    end

    def render_tag_cloud(tags, options = {})
      return nil if tags.nil?
      # TODO: add options to specify different limits and sorts
      #tags = Tag.all(:limit => 100, :order => 'taggings_count DESC').sort_by(&:name)

      # TODO: add option to specify which classes you want and overide this if you want?
      classes = %w(popular v-popular vv-popular vvv-popular vvvv-popular)

      max, min = 0, 0
      tags.each do |tag|
        #if options[:max] or options[:min]
        #  max = options[:max].to_i
        #  min = options[:min].to_i
        #end
        max = tag.taggings.size if tag.taggings.size > max
        min = tag.taggings.size if tag.taggings.size < min
      end
      divisor = ((max - min).div(classes.size)) + 1

      html =    %(<div class="hTagcloud">\n)
      html <<   %(  <ul class="popularity">\n)
      tags.each do |tag|
        html << %(  <li>)
        html << link_to(tag.name, manifestations_path(:tag => tag.name), :class => classes[(tag.taggings.size - min).div(divisor)])
        html << %(  </li>\n) # FIXME: IEのために文末の空白を入れている
      end
      html <<   %(  </ul>\n)
      html <<   %(</div>\n)
      html.html_safe
    end

    def agents_list(agents = [], options = {}, manifestation_id = nil, type = nil, mode = 'html')
      return nil if agents.blank?
      agents_list = []
      exclude_agents = SystemConfiguration.get("exclude_agents").split(',').inject([]){ |list, word| list << word.gsub(/^[　\s]*(.*?)[　\s]*$/, '\1') }
      agents.each do |agent|
        type_name = ''
        if manifestation_id.present? && SystemConfiguration.get("use_agent_type")
          case type
            when 'create'
              create_type = CreateType.find(agent.creates.where(work_id: manifestation_id).first.create_type_id) rescue nil
              type_name = (create_type and create_type.display) ? create_type.display_name : ''
            when 'realize'
              realize_type = RealizeType.find(agent.realizes.where(expression_id: manifestation_id).first.realize_type_id) rescue nil
              type_name = (realize_type and realize_type.display) ? realize_type.display_name : ''
            when 'produce'
              produce_type = ProduceType.find(agent.produces.where(manifestation_id: manifestation_id).first.produce_type_id) rescue nil
              type_name = (produce_type and produce_type.display) ? produce_type.display_name : ''
          end
          type_name = type_name.blank? ? '' : '(' + type_name.localize + ')'
        end
        full_name = agent.full_name << type_name
        if options[:nolink] or exclude_agents.include?(agent.full_name)
          agent = mode == 'html' ? highlight(full_name) : full_name
        else
          agent = mode == 'html' ? link_to(highlight(full_name), agent, options) : link_to(full_name, agent, options)
        end
        agents_list << agent
      end
      agents_list.join(" ").html_safe
    end

    def agents_short_list(agents = [], options = {})
      return nil if agents.blank?
      agents_list = []
      agents.each_with_index do |agent, i|
        if i < 3
          if options[:nolink]
            agents_list << agent.full_name
          else
            agents_list << link_to(agent.full_name, agent, options)
          end
        end
      end
      agents_list << '...' if agents.size > 3
      agents_list.join(" ").html_safe
    end

    def book_jacket(manifestation)
      if manifestation.picture_files.exists?
        link = ''
        manifestation.picture_files.each_with_index do |picture_file, i|
          if i == 0
            link += link_to(show_image(picture_file, :size => :thumb), picture_file_path(picture_file, :format => picture_file.extname), :rel => "manifestation_#{manifestation.id}")
          else
            link += '<span style="display: none">' + link_to(show_image(picture_file, :size => :thumb), picture_file_path(picture_file, :format => picture_file.extname), :rel => "manifestation_#{manifestation.id}") + '</span>'
          end
        end
        return link.html_safe
      else
        link = book_jacket_tag(manifestation)
        unless link
          link = screenshot_tag(manifestation)
        end
      end

      unless link
        link = link_to image_tag('unknown_resource.png', :width => '100', :height => '100', :alt => '*', :itemprop => 'image'), manifestation
      end
      link
    #rescue NoMethodError
    #  nil
    end

    def database_adapter
      case ActiveRecord::Base.configurations["#{Rails.env}"]['adapter']
      when 'postgresql'
        link_to 'PostgreSQL', 'http://www.postgresql.org/'
      when 'jdbcpostgresql'
        link_to 'PostgreSQL', 'http://www.postgresql.org/'
      when 'mysql'
        link_to 'MySQL', 'http://www.mysql.org/'
      when 'jdbcmysql'
        link_to 'MySQL', 'http://www.mysql.org/'
      when 'sqlite3'
        link_to 'SQLite', 'http://www.sqlite.org/'
      when 'jdbcsqlite3'
        link_to 'SQLite', 'http://www.sqlite.org/'
      end
    end

    def title_action_name
      case controller.action_name
      when 'index'
        t('title.index')
      when 'show'
        t('title.show')
      when 'new'
        t('title.new')
      when 'edit'
        t('title.edit')
      end
    end

    def link_to_wikipedia(string)
      link_to "Wikipedia", "http://#{I18n.locale}.wikipedia.org/wiki/#{URI.escape(string)}"
    end

    def locale_display_name(locale)
      Language.where(:iso_639_1 => locale).first.display_name
    end

    def locale_native_name(locale)
      Language.where(:iso_639_1 => locale).first.native_name
    end

    def move_position(object)
      render :partial => 'page/position', :locals => {:object => object}
    end

    def localized_boolean(bool)
      case bool.to_s
      when nil
      when "true"
        t('page.boolean.true')
      when "false"
        t('page.boolean.false')
      end
    end

    def current_user_role_name
      current_user.try(:role).try(:name) || 'Guest'
    end

    def title(controller_name)
      string = ''
      unless controller_name == 'page' or controller_name == 'my_accounts' or controller_name == 'opac'
        string << t("activerecord.models.#{controller_name.singularize}") + ' - '
      end
      string << LibraryGroup.system_name + ' - Next-L Enju Trunk'
      string.html_safe
    end

    def back_to_index(options = {})
      if options == nil
        options = {}
      else
        options.reject!{|key, value| value.blank?}
        options.delete(:page) if options[:page].to_i == 1
      end
      unless controller_name == 'test'
        link_to t('page.listing', :model => t("activerecord.models.#{controller_name.singularize}")), url_for(params.merge(:controller => controller_name, :action => :index, :id => nil).merge(options))
      end
    end

    def user_notice(user)
      string = ''
      messages = user.user_notice
      messages.each do |message|
        string << message.gsub("[","").gsub("]", "") + '<br />'
      end
      string.html_safe
    end

    def wareki_dateformat(v)
      ja_wmd(v)
    end

    def dateformat(v)
      return "" if v.nil?
      v.strftime "%Y/%m/%d %H:%M:%S" rescue ""
    end

    def term_check(start_d, end_d)
      return t('page.exstatistics.nil_date') if start_d.blank? or end_d.blank?
      return t('page.exstatistics.invalid_input_date') unless start_d =~ /^((\d+)-?)*\d$/
      return t('page.exstatistics.invalid_input_date') unless end_d =~ /^((\d+)-?)*\d$/
      return t('page.exstatistics.invalid_input_date') if date_format_check(start_d) == nil
      return t('page.exstatistics.invalid_input_date') if date_format_check(end_d) == nil
      return t('page.exstatistics.over_end_date') if end_d.gsub(/\D/, '') < start_d.gsub(/\D/, '')
      nil
    end

    def date_format_check(date)
      date = date.to_s.gsub(/\D/, '')
      return nil if date == nil or date.length != 8
      year = date[0, 4].to_i
      month = date[4, 2].to_i
      day = date[6, 4].to_i
      return nil unless Date.valid_date?(year, month, day)
      date = Time.zone.parse(date)
    end

    def clinet_is_special_ip?
      special_ip_address_list = SystemConfiguration.get("special_ip_address_list").split(",") rescue [""]
      remote_ip = request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip
      special_ip_address_list.include?(remote_ip)
    end

    ADVANCED_SEARCH_PARAMS = [
      :except_query, :tag, :title, :except_title, :creator, :except_creator,
      :publisher, :isbn, :issn, :ndc, :item_identifier, :pub_date_from,
      :edition_display_value, :volume_number_string, :issue_number_string, :serial_number_string,
      :pub_date_to, :acquired_from, :acquired_to, :removed_from, :removed_to,
      :number_of_pages_at_least, :number_of_pages_at_most, :advanced_search,
      :title_merge, :creator_merge, :query_merge, :manifestation_types,
      :carrier_types, :identifier, :other_identifier, :identifier_type,
      :classifications,
    ]

    ADVANCED_SEARCH_LABEL_IDS = {
      tag: 'page.tag',
      title: 'page.title',
      creator: 'agent.creator',
      subject: 'activerecord.models.subject',
      publisher: 'agent.publisher',
      isbn: 'activerecord.attributes.manifestation.isbn',
      issn: 'activerecord.attributes.manifestation.issn',
      ndc: 'activerecord.attributes.manifestation.ndc',
      edition_display_value: 'activerecord.attributes.manifestation.edition_display_value',
      volume_number_string: 'activerecord.attributes.manifestation.volume_number_string',
      issue_number_string: 'activerecord.attributes.manifestation.issue_number_string',
      serial_number_string: 'activerecord.attributes.manifestation.serial_number_string',
      ncid: 'activerecord.attributes.nacsis_user_request.ncid',
      item_identifier: 'activerecord.attributes.item.item_identifier',
      call_number: 'activerecord.attributes.item.call_number',
      pub_date: 'activerecord.attributes.manifestation.date_of_publication',
      acquired: 'activerecord.attributes.item.acquired_at',
      removed: 'activerecord.attributes.item.removed_at',
      number_of_pages: 'page.number_of_pages',
      exact_title: 'page.exact_title',
      startwith_title: 'page.startwith_title',
      all_title: 'page.all_title',
      any_title: 'page.any_title',
      except_title: 'page.except_title',
      exact_creator: 'page.exact_creator',
      startwith_creator: 'page.startwith_creator',
      all_creator: 'page.all_creator',
      any_creator: 'page.any_creator',
      except_creator: 'page.except_creator',
      query: 'page.search_term',
      all_query: 'page.all_search_term',
      any_query: 'page.any_search_term',
      except_query: 'page.except_search_term',
      startwith_query: 'page.startwith_term',
      solr_query: 'page.solr_query',
      manifestation_types: 'activerecord.models.manifestation_type',
      carrier_types: 'activerecord.models.carrier_type',
      identifier: 'activerecord.attributes.manifestation.identifier',
      other_identifier: 'activerecord.models.identifier',
      classifications: 'activerecord.models.classification',
    }

    def advanced_search_label(key)
      I18n.t(ADVANCED_SEARCH_LABEL_IDS[key])
    end

    def link_to_advanced_search(link_title = nil)
      link_title ||= t('page.advanced_search')
      url_params = params.dup

      [:controller, :commit, :utf8, :mode].each {|k| url_params.delete(k) }
      link_to link_title, page_advanced_search_path(url_params)
    end

    def link_to_normal_search(link_title = nil)
      if params[:mode].present?
        return '' if params[:mode] != 'recent'
      else
        return '' if ADVANCED_SEARCH_PARAMS.all? {|k| params[k].blank? } and params[:solr_query].blank?
      end

      link_title ||= t('page.normal_search')
      url_params = params.dup
      [:controller, :commit, :utf8].each {|k| url_params.delete(k) }
      url_params.delete('mode') if params[:mode].present? and params[:mode] == 'recent'
      url_params.delete('solr_query') if params[:solr_query].present?
      ADVANCED_SEARCH_PARAMS.each {|k| url_params.delete(k)}
      link_to link_title, manifestations_path(url_params)
    end

    def hidden_advanced_search_field_tags
      array = []
      ADVANCED_SEARCH_PARAMS.map do |name|
        if name == :manifestation_types
          next unless params[name]
          params[name].keys.each do |key|
            array << hidden_field_tag("#{name.to_s}[#{key}]", true)
          end
        elsif name == :classifications
          next unless params[name]
          params[name].each do |kvs|
            kvs.each do |key, value|
              array << hidden_field_tag("#{name.to_s}[][#{key}]", value)
            end
          end
        else
          array << hidden_field_tag(name.to_s, params[name])
        end
      end
      array.join('').html_safe
    end

    def advanced_search_condition_summary(opts = {})
      return "(#{I18n.t('page.new_resource')})" if params[:mode] == 'recent'
      return "(#{params[:solr_query]})" if params[:solr_query].present?

      summary_ary = []
      special = {
        title: nil,
        creator: nil,
        pub_date: nil,
        acquired: nil,
        removed: nil,
        number_of_pages: nil,
      }
      range_delimiter = '-'

      ADVANCED_SEARCH_PARAMS.each do |key|
        next if key == :advanced_search
        next unless params[key]

        case key
        when :pub_date_from, :pub_date_to,
            :acquired_from, :acquired_to,
            :removed_from, :removed_to,
            :number_of_pages_at_least, :number_of_pages_at_most
          t = key.to_s.sub(/_(from|to|at_least|at_most)\z/, '').to_sym
          i = ($1 == 'from' || $1 == 'at_least') ? 0 : 2

          if params[key].present? && special[t].nil?
            special[t] = ['', range_delimiter, '']
            summary_ary << [t, special[t]]
          end
          special[t][i] = params[key] if special[t]

        when :title, :creator, :title_merge, :creator_merge, :query_merge
          t = key.to_s.sub(/(_merge)?\z/, '').to_sym
          v = nil
          if $1
            i = 1
            if params[t].present? && /\A(?:all|any|exact|startwith)\z/ =~ params[key].to_s
              v = "[#{advanced_search_label(:"#{params[key]}_#{t}")}]"
            end
          else
            i = 0
            v = params[key] if params[key].present?
          end

          if v && special[t].nil?
            special[t] = ['', '']
            summary_ary << [t, special[t]]
          end
          special[t][i] = v if special[t]

        when :except_query, :except_title, :except_creator, :except_publisher
          k = key.to_s.sub(/\Aexcept_/, '').to_sym

          if params[key].present? && params[k].present?
            summary_ary << ["#{advanced_search_label(key)}#{advanced_search_label(k)}", params[key]]
          end

        when :manifestation_types
          ks = ManifestationType.where(["id in (?)", params[key].keys]).map{|mt| mt.display_name.localize}
          summary_ary << [key, ks.join(', ')] if params[key].present?

        when :classifications
          cls_ids = (params[key] || []).inject([]) {|ary, kvs| ary << kvs['classification_id'] }.compact
          if cls_ids.present?
            cls_cats = Classification.where(id: cls_ids).includes(:classification_type).map do | cls|
              "#{cls.classification_type.display_name} #{cls.category}"
            end
            summary_ary << [key, cls_cats.join(', ')] if cls_cats.present?
          end

        else
          summary_ary << [key, params[key]] if params[key].present?
        end
      end

      return '' if summary_ary.blank?

      omission = ''
      if opts[:length] && summary_ary.size > opts[:length]
        summary_ary = summary_ary[0, opts[:length]]
        omission = opts[:omission] if opts[:omission]
      end

      '(' + summary_ary.map do |label_id, data|
        if data.is_a?(Array)
          if data.any?(&:present?)
            data = data.join('')
          else
            data = nil
          end
        else
          data = data.to_s
        end

        label = label_id.is_a?(Symbol) ? advanced_search_label(label_id) : label_id
        "#{label}: #{data}"
      end.join(I18n.t('page.list_delimiter')) + omission + ')'
    end

    def advanced_search_merge_tag(name)
      pname = :"#{name}_merge"
      all = any = exact = startwith = false

      case params[pname]
      when 'any'
        any = true
      when 'exact'
        if name == 'query'
          all = true
        else
          exact = true
        end
      when 'startwith'
        startwith = true
      else
        all = true
      end

      (if name == 'query'
          ''
        else
          radio_button_tag(pname, 'exact', exact) +
          advanced_search_label(:"exact_#{name}") + ' '
        end +
        radio_button_tag(pname, 'startwith', startwith) +
        advanced_search_label(:"startwith_#{name}") + ' ' +
        radio_button_tag(pname, 'all', all) +
        advanced_search_label(:"all_#{name}") + ' ' +
        radio_button_tag(pname, 'any', any) +
        advanced_search_label(:"any_#{name}") + ' '
      ).html_safe
    end

    def hbr(target)
      target = html_escape(target)
      target.gsub(/\r\n|\r|\n/, "<br />")
    end

    # @highlightに設定された正規表現に基きspanタグを挿入する
    # html_safeを適用した文字列を返す
    def highlight(str)
      html = ''
      str = str.dup
      while @highlight =~ str
        html << escape_once($`)
        html << content_tag(:span, :class => 'highlight') { $& }
        str = $'
      end
      html << escape_once(str)
      html.html_safe
    end

    def tab_menu_width
      # ライブラリアン権限時未満のとき、タブメニューの表示内容に伴いタブのサイズも変更する
      if user_signed_in?
        unless current_user.has_role?('Librarian')
          # ゲスト権限以上ユーザ権限未満でログイン時
          return (can_use_purchase_request? or
            SystemConfiguration.get('use_copy_request') or
            SystemConfiguration.get("user_show_questions")) ?
              'fg-4button' : 'fg-3button'
        end
      else
        # 未ログイン時
        return (can_use_purchase_request? or SystemConfiguration.get('use_copy_request')) ? 'fg-4button' : 'fg-3button'
      end
    end

    def get_detail_name(model, primary, secondary = '')
      return '' if model.blank? or primary.blank?
      name_ary = model.display_name.localize.split(/[,:]/, -1) rescue []
      return name_ary.first if name_ary.size.odd?
      name_hash = Hash[*name_ary]
      return name_hash[primary] unless name_hash[primary].blank?
      return name_hash[secondary] unless name_hash[secondary].blank?
    end

    if defined?(EnjuTrunkCirculation)
      def i18n_state(state)
        case state
        when 'pending'
          I18n.t('reserve.pending')
        when 'requested'
          I18n.t('reserve.requested')
        when 'retained'
          I18n.t('reserve.retained')
        when 'in_process'
          I18n.t('reserve.in_process')
        when 'canceled'
          I18n.t('reserve.canceled')
        when 'expired'
          I18n.t('reserve.expired')
        when 'completed'
          I18n.t('reserve.completed')
        end
      end
      def i18n_information_type(id)
        case id
        when 0
          I18n.t('activerecord.attributes.reserve.unnecessary')
        when 1
          I18n.t('activerecord.attributes.reserve.email')
        when [2, 3, 4, 5, 6, 7], 2, 3, 4, 5, 6, 7
          I18n.t('activerecord.attributes.reserve.telephone')
        end
      end
    end

    def select2(selector_id, selector_name, collection, selected_id, *options)
      options = options.first # if options.is_a?(Array)　

      b = ""
      b.concat(select2_script(selector_id))
      b.concat(build_select2(selector_id, selector_name, collection, selected_id, options))
      return raw(b)
    end

    def build_select2(selector_id, selector_name, collection, selected_id, options)
      include_blank = options[:include_blank] || false
      alt_display = options[:alt_display] || true
      width = options[:width] || 300
      select_attribute = options[:select_attribute] || :v
      display_attribute = options[:display_attribute] || :keyname
      post_attribute = options[:post_attribute] || :id

      html = raw ("<select id=\"#{selector_id}\" name=\"#{selector_name}\" style=\"width:#{width}px\">\n")
      if include_blank
        html.concat( raw ("<option alt=\"blank\", value=\"\"> </option>\n") )
      end
      collection.each do |row|
        html.concat( raw ("      <option alt=\"#{ row.send(select_attribute) }\", value=\"#{ row.send(post_attribute) }\"") )
        if selected_id == row.id
          html.concat( raw (", selected=\"selected\"") )
        end

        html.concat( raw (">#{ row.send(display_attribute).localize }") )

        if alt_display
          html.concat( raw (" (#{ row.send(select_attribute) })") )
        end
        html.concat( raw ("</option>\n") )
      end
      html.concat( raw ("    </select>\n") )
    end

    def select2_script(selector_id)
      raw ("
        <script>
          $(document).ready(function() {
            $(\"##{selector_id}\").select2({
              matcher: function(term, text, opt) {
                return text.toUpperCase().indexOf(term.toUpperCase())==0
                    || opt.attr(\"alt\").toUpperCase().indexOf(term.toUpperCase())==0;
              }
            });
          });
        </script>
      ")
    end

    def make_select2(selector_id, selector_name, data, obj_data, width, include_blank=false, alt_display=true)
      html = raw ("<select id=\"#{selector_id}\" name=\"#{selector_name}\" style=\"width:#{width}px\">\n")
      if include_blank
        html.concat( raw ("<option alt=\"blank\", value=\"\"> </option>\n") )
      end
      data.each do |data|
        html.concat( raw ("      <option alt=\"#{ data.name }\", value=\"#{ data.id }\"") )
        if obj_data == data.id
          html.concat( raw (", selected=\"selected\"") )
        end

        if data.attribute_present?(:display_name)
          html.concat( raw (">#{ data.display_name.localize }") )
        else
          html.concat( raw (">#{ data.name.localize }") )
        end

        if alt_display
          html.concat( raw (" (#{ data.name })") )
        end
        html.concat( raw ("</option>\n") )
      end
      html.concat( raw ("    </select>\n") )
    end

    def make_select2_struct(selector_id, selector_name, data, obj_data, width, include_blank=false, alt_display=true)
      html = raw ("<select id=\"#{selector_id}\" name=\"#{selector_name}\" style=\"width:#{width}px\">\n")
      if include_blank
        html.concat( raw ("<option alt=\"blank\", value=\"\"> </option>\n") )
      end
      data.each do |data|
        html.concat( raw ("      <option alt=\"#{ data.name }\", value=\"#{ data.id }\"") )
        if obj_data == data.id
          html.concat( raw (", selected=\"selected\"") )
        end

        html.concat( raw (">#{ data.display_name }") )

        if alt_display
          html.concat( raw (" (#{ data.name })") )
        end
        html.concat( raw ("</option>\n") )
      end
      html.concat( raw ("    </select>\n") )
    end

    def markdown(text)
      unless @markdown
        renderer = Redcarpet::Render::HTML.new
        @markdown = Redcarpet::Markdown.new(renderer, no_links: true, hard_wrap: true)
      end

      @markdown.render(text).html_safe
    end

    def numberings
      list = []
      @numberings.each do |numbering|
        list << Manifestation::SELECT2_OBJ.new(numbering.name, numbering.name, numbering.display_name)
      end
      return list
    end
  end
end
