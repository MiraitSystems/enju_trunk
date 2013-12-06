class PatronImportFile < ActiveRecord::Base
  attr_accessible :patron_import, :edit_mode
  include ImportFile
  default_scope :order => 'id DESC'
  scope :not_imported, where(:state => 'pending', :imported_at => nil)
  scope :stucked, where('created_at < ? AND state = ?', 1.hour.ago, 'pending')

  if Setting.uploaded_file.storage == :s3
    has_attached_file :patron_import, :storage => :s3, :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => "patron_import_files/:id/:filename",
      :s3_permissions => :private
  else
    has_attached_file :patron_import, :path => ":rails_root/private:url"
  end
  validates_attachment_content_type :patron_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/vnd.ms-excel'], :unless => proc{ SystemConfiguration.get("set_output_format_type") }
  validates_attachment_content_type :patron_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/octet-stream'], :if => proc{ SystemConfiguration.get("set_output_format_type") }
  validates_attachment_presence :patron_import
  belongs_to :user, :validate => true
  has_many :patron_import_results

  before_create :set_digest

  state_machine :initial => :pending do
    event :sm_start do
      transition [:pending, :started] => :started
    end

    event :sm_complete do
      transition :started => :completed
    end

    event :sm_fail do
      transition :started => :failed
    end
  end

  def set_digest(options = {:type => 'sha1'})
    if File.exists?(patron_import.queued_for_write[:original])
      self.file_hash = Digest::SHA1.hexdigest(File.open(patron_import.queued_for_write[:original].path, 'rb').read)
    end
  end

  def import_start
    sm_start!
    case edit_mode
    when 'create'
      import
    when 'update'
      import
    when 'destroy'
      remove
    else
      import
    end
  end

  def import
#日本語化
    username = I18n.t('activerecord.attributes.user.username')
    user_number = I18n.t('activerecord.attributes.user.user_number')
    full_name = I18n.t('activerecord.attributes.patron.full_name')
    del_flg = I18n.t('resource_import_textfile.excel.book.del_flg')

    self.reload
    num = {:patron_imported => 0, :user_imported => 0, :failed => 0}
    row_num = 2
    rows = open_import_file
    field = rows.first     
    rows.each do |row|
      next if row['dummy'].to_s.strip.present?
      if SystemConfiguration.get("set_output_format_type") == false
        import_result = PatronImportResult.create!(:patron_import_file => self, :body => row.fields.join(","))
      else
        import_result = PatronImportResult.create!(:patron_import_file => self, :body => row.fields.join("\t"))
      end

      delete_flag = row[del_flg]
      puts("#####################################")
      puts delete_flag

      unless (delete_flag == "delete" || delete_flag == "false" || delete_flag.blank?)
        puts("delete")
        begin
          user = User.where(:user_number => row[user_number].to_s.strip).first
          import_result.error_msg = "#{user.patron.full_name} delete"
          user.destroy
          num[:patron_imported] += 1
          num[:user_imported] += 1
        rescue Exception => e
          import_result.error_msg = "FAIL[#{row_num}]: #{e}"
          Rails.logger.info("patron import failed: column #{row_num}")
          num[:failed] += 1
        end
      else
        user = User.where(:user_number => row[user_number].to_s.strip).first
        if user.blank? 
          puts("insert")
          begin
            patron = Patron.new
            patron = set_patron_value(patron, row)

            if patron.save!
              import_result.patron = patron
              num[:patron_imported] += 1
              if row_num % 50 == 0
                Sunspot.commit
                GC.start
              end
            end
          rescue Exception => e
            import_result.error_msg = "FAIL[#{row_num}]: #{e}" 
            Rails.logger.info("patron import failed: column #{row_num}")
            num[:failed] += 1
          end

          unless row[username].to_s.strip.blank?
            begin
              user = User.new
              user.patron = patron
              set_user_value(user, row)
              if user.password.blank?
                user.set_auto_generated_password
              end
              if user.save!
                import_result.user = user
              end
              num[:user_imported] += 1
            rescue ActiveRecord::RecordInvalid => e
              import_result.error_msg = "FAIL[#{row_num}]: #{e}" 
              Rails.logger.info("user import failed: column #{row_num}")
            end
          end
        else
          puts ("update!")
          if user.try(:patron)
            begin
              patron = set_patron_value(user.patron, row)
              set_user_value(user, row)
              if patron.save
                import_result.patron = patron
              end
              if user.save!
                import_result.user = user
              end
              num[:user_imported] += 1
            rescue ActiveRecord::RecordInvalid => e
              import_result.error_msg = "FAIL[#{row_num}]: #{e}" 
              Rails.logger.info("update failed: column #{row_num}")
              num[:failed] += 1
            end
          end
        end
      end
      import_result.save!
      row_num += 1
    end
    self.update_attribute(:imported_at, Time.zone.now)
    Sunspot.commit
    rows.close
    sm_complete!
    return num
  end

  def self.import(id = nil)
    #PatronImportFile.not_imported.each do |file|
    #  file.import_start
    #end
    if !id.nil?
      file = PatronImportFile.find(id) rescue nil
      file.import_start unless file.nil?
    else
      PatronImportFile.not_imported.each do |file|
        file.import_start
      end
    end
  rescue
    logger.error "#{Time.zone.now} importing patrons failed!"
    logger.error $@
  end

  def modify
    self.reload
    user_number = I18n.t('activerecord.attributes.user.user_number')
    username = I18n.t('activerecord.attributes.user.username')
    num = {:patron_imported => 0, :user_imported => 0, :failed => 0}
    rows = open_import_file
    field = rows.first
    row_num = 2
    rows.each do |row|
      next if row['dummy'].to_s.strip.present?
      user = User.where(:user_number => row[user_number].to_s.strip).first
      if SystemConfiguration.get("set_output_format_type") == false
        import_result = PatronImportResult.create!(:patron_import_file => self, :body => row.fields.join(","))
      else
        import_result = PatronImportResult.create!(:patron_import_file => self, :body => row.fields.join("\t"))
      end
      if user.try(:patron)
        begin
          #更新用にまず削除
          set_patron_value(user.patron, row)
          set_user_value(user, row)
          user.destroy
          #削除したものを更新
          user = User.new
          patron = Patron.new
          patron = set_patron_value(patron, row)
          user.patron = patron
          set_user_value(user, row)
          if user.password.blank?
            user.set_auto_generated_password
          end
          if user.patron.save!
            import_result.patron = patron
          end 
          if user.save!
            import_result.user = user
          end
          num[:patron_imported] += 1
          num[:user_imported] += 1
        rescue Exception => e
          import_result.error_msg = "FAIL[#{row_num}]: #{e}"
          Rails.logger.info("patron import failed: column #{row_num}")
          num[:failed] += 1
        end
      else
        import_result.error_msg = "FAIL[#{row_num}]: faild" 
      end
      import_result.save!
      row_num += 1
    end
    self.update_attribute(:imported_at, Time.zone.now)
    rows.close
    sm_complete!
    return num
  end

  def remove
    self.reload
    user_number = I18n.t('activerecord.attributes.user.user_number')
    num = {:patron_imported => 0, :user_imported => 0, :failed => 0}
    rows = open_import_file
    field = rows.first
    row_num = 2   
    rows.each do |row|
      next if row['dummy'].to_s.strip.present?

      if SystemConfiguration.get("set_output_format_type") == false
        import_result = PatronImportResult.create!(:patron_import_file => self, :body => row.fields.join(","))
      else
        import_result = PatronImportResult.create!(:patron_import_file => self, :body => row.fields.join("\t"))
      end

      user = User.new
      patron = Patron.new
      set_patron_value(patron, row)
      import_result.patron = patron
      set_user_value(user, row)
      import_result.user = user
      begin
        user = User.where(:user_number => row[user_number].to_s.strip).first
        user.destroy
        num[:patron_imported] += 1
        num[:user_imported] += 1
      rescue Exception => e
        import_result.error_msg = "FAIL[#{row_num}]: #{e}"
        Rails.logger.info("patron import failed: column #{row_num}")
        num[:failed] += 1
      end
      import_result.save!
      row_num += 1
    end
    self.update_attribute(:imported_at, Time.zone.now)
    rows.close
    sm_complete!
    return num
  end

  private
  def open_import_file
    tempfile = Tempfile.new('patron_import_file')
    if Setting.uploaded_file.storage == :s3
      uploaded_file_path = open(self.patron_import.expiring_url(10)).path
    else
      uploaded_file_path = self.patron_import.path
    end
    open(uploaded_file_path){|f|
      f.each{|line|
        tempfile.puts(NKF.nkf('-w -Lu', line))
      }
    }
    tempfile.close

    if RUBY_VERSION > '1.9'
      if SystemConfiguration.get("set_output_format_type") == false
        file = CSV.open(tempfile, :col_sep => ",")
        header = file.first
        rows = CSV.open(tempfile, :headers => header, :col_sep => ",")
      else
        file = CSV.open(tempfile, :col_sep => "\t")
        header = file.first
        rows = CSV.open(tempfile, :headers => header, :col_sep => "\t")
      end
    else
      if SystemConfiguration.get("set_output_format_type") == false
        file = FasterCSV.open(tempfile.path, :col_sep => ",")
        header = file.first
        rows = FasterCSV.open(tempfile.path, :headers => header, :col_sep => ",")
      else
        file = FasterCSV.open(tempfile.path, :col_sep => "\t")
        header = file.first
        rows = FasterCSV.open(tempfile.path, :headers => header, :col_sep => "\t")
      end
    end
    if SystemConfiguration.get("set_output_format_type") == false
      PatronImportResult.create(:patron_import_file => self, :body => header.join(","), :error_msg => 'HEADER DATA')
    else
      PatronImportResult.create(:patron_import_file => self, :body => header.join("\t"), :error_msg => 'HEADER DATA')
    end
    tempfile.close(true)
    file.close
    rows
  end

  def set_patron_value(patron, row)
#日本語化
      full_name = I18n.t('activerecord.attributes.patron.full_name')
      full_name_transcription = I18n.t('activerecord.attributes.patron.full_name_transcription')
      full_name_alternative = I18n.t('activerecord.attributes.patron.full_name_alternative')
      first_name = I18n.t('activerecord.attributes.patron.first_name')
      first_name_transcription = I18n.t('activerecord.attributes.patron.first_name_transcription')
      last_name = I18n.t('activerecord.attributes.patron.last_name')
      last_name_transcription = I18n.t('activerecord.attributes.patron.last_name_transcription')
      username = I18n.t('activerecord.attributes.user.username')
      patron_type = I18n.t('activerecord.models.patron_type')
      url = I18n.t('activerecord.attributes.patron.url')
      email = I18n.t('activerecord.attributes.patron.email')
      other_designation = I18n.t('activerecord.attributes.patron.other_designation')
      place = I18n.t('activerecord.attributes.patron.place')
      language = I18n.t('activerecord.models.language')
      country = I18n.t('activerecord.models.country')
      zip_code_1 = I18n.t('activerecord.attributes.patron.zip_code_1')
      address_1 = I18n.t('activerecord.attributes.patron.address_1')
      telephone_number_1 = I18n.t('activerecord.attributes.patron.telephone_number_1')
      telephone_number_1_type_id = I18n.t('activerecord.attributes.patron.telephone_number_1_type')
      extelephone_number_1 = I18n.t('activerecord.attributes.patron.extelephone_number_1')
      extelephone_number_1_type_id = I18n.t('activerecord.attributes.patron.extelephone_number_1_type')
      fax_number_1 = I18n.t('activerecord.attributes.patron.fax_number_1')
      fax_number_1_type_id = I18n.t('activerecord.attributes.patron.fax_number_1_type')
      address_1_note = I18n.t('activerecord.attributes.patron.address_1_note')
      zip_code_2 = I18n.t('activerecord.attributes.patron.zip_code_2')
      address_2 = I18n.t('activerecord.attributes.patron.address_2')
      telephone_number_2 = I18n.t('activerecord.attributes.patron.telephone_number_2')
      telephone_number_2_type_id = I18n.t('activerecord.attributes.patron.telephone_number_2_type')
      extelephone_number_2 = I18n.t('activerecord.attributes.patron.extelephone_number_2')
      extelephone_number_2_type_id = I18n.t('activerecord.attributes.patron.extelephone_number_2_type')
      fax_number_2 = I18n.t('activerecord.attributes.patron.fax_number_2')
      fax_number_2_type_id = I18n.t('activerecord.attributes.patron.fax_number_2_type')
      address_2_note = I18n.t('activerecord.attributes.patron.address_2_note')
      birth_date = I18n.t('activerecord.attributes.patron.date_of_birth')
      death_date = I18n.t('activerecord.attributes.patron.date_of_death')
      note = I18n.t('activerecord.attributes.patron.note')
      note_update_at = I18n.t('activerecord.attributes.patron.note_update_at')
      note_update_by = I18n.t('activerecord.attributes.patron.note_update_by')
      note_update_library = I18n.t('activerecord.attributes.patron.note_update_library')
      patron_identifier = I18n.t('patron.patron_identifier')

    patron.first_name = row[first_name] if row[first_name]
    #patron.middle_name = row[middle_name] if row[middle_name]
    patron.last_name = row[last_name] if row[last_name]
    patron.first_name_transcription = row[first_name_transcription] if row[first_name_transcription]
    #patron.middle_name_transcription = row[middle_name_transcription] if row[middle_name_transcription]
    patron.last_name_transcription = row[last_name_transcription] if row[last_name_transcription]

    patron.full_name = row[full_name] if row[full_name]
    patron.full_name_transcription = row[full_name_transcription] if row[full_name_transcription]
    patron.full_name_alternative = row[full_name_alternative] if row[full_name_alternative]

    patron.address_1 = row[address_1] if row[address_1]
    patron.address_2 = row[address_2] if row[address_2]
    patron.zip_code_1 = row[zip_code_1] if row[zip_code_1]
    patron.zip_code_2 = row[zip_code_2] if row[zip_code_2]
 
    if row[telephone_number_1]
      patron.telephone_number_1 = row[telephone_number_1]
      type_id = row[telephone_number_1_type_id].to_i rescue 0
      patron.telephone_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[telephone_number_2]
      patron.telephone_number_2 = row[telephone_number_2]
      type_id = row[telephone_number_2_type_id].to_i rescue 0
      patron.telephone_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[extelephone_number_1]
      patron.extelephone_number_1 = row[extelephone_number_1]
      type_id = row[extelephone_number_1_type_id].to_i rescue 0
      patron.extelephone_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[extelephone_number_2]
      patron.extelephone_number_2 = row[extelephone_number_2]
      type_id = row[extelephone_number_2_type_id].to_i rescue 0
      patron.extelephone_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[fax_number_1]
      patron.fax_number_1 = row[fax_number_1]
      type_id = row[fax_number_1_type_id].to_i rescue 0
      patron.fax_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[fax_number_2]
      patron.fax_number_2 = row[fax_number_2]
      type_id = row[fax_number_2_type_id].to_i rescue 0
      patron.fax_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end

    patron.address_1_note = row[address_1_note] if row[address_1_note]
    patron.address_2_note = row[address_2_note] if row[address_1_note]
    patron.note = row[note] if row[note]
    patron.note_update_at = row[note_update_at] if row[note_update_at]
    patron.note_update_by = row[note_update_by] if row[note_update_by]
    patron.note_update_library = row[note_update_library] if row[note_update_library]
    patron.birth_date = row[birth_date] if row[birth_date]
    patron.death_date = row[death_date] if row[death_date]
    patron.patron_type_id = row[patron_type] unless row[patron_type].to_s.strip.blank?
    patron.url = row[url].to_s.strip if row[url]
    patron.other_designation = row[other_designation].to_s.strip if row[other_designation]
    patron.place = row[place].to_s.strip if row[place]
    patron.email = row[email].to_s.strip if row[email]

    if row[username].to_s.strip.blank?
    #  #patron.email = row[email].to_s.strip
      patron.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Guest')
    else
      patron.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Librarian')
    end
    language = Language.where(:name => row[language].to_s.strip.camelize).first
    language = Language.where(:iso_639_2 => row[language].to_s.strip.downcase).first unless language
    language = Language.where(:iso_639_1 => row[language].to_s.strip.downcase).first unless language
    patron.language = language if language
    country = Country.where(:name => row[country].to_s.strip).first
    patron.country = country if country
    patron.patron_identifier = row[patron_identifier].to_s.strip if row[patron_identifier]

=begin
    patron.first_name = row['first_name'] if row['first_name']
    patron.middle_name = row['middle_name'] if row['middle_name']
    patron.last_name = row['last_name'] if row['last_name']
    patron.first_name_transcription = row['first_name_transcription'] if row['first_name_transcription']
    patron.middle_name_transcription = row['middle_name_transcription'] if row['middle_name_transcription']
    patron.last_name_transcription = row['last_name_transcription'] if row['last_name_transcription']

    patron.full_name = row['full_name'] if row['full_name']
    patron.full_name_transcription = row['full_name_transcription'] if row['full_name_transcription']
    patron.full_name_alternative = row['full_name_alternative'] if row['full_name_alternative']

    patron.address_1 = row['address_1'] if row['address_1']
    patron.address_2 = row['address_2'] if row['address_2']
    patron.zip_code_1 = row['zip_code_1'] if row['zip_code_1']
    patron.zip_code_2 = row['zip_code_2'] if row['zip_code_2']
    if row['telephone_number_1']
      patron.telephone_number_1 = row['telephone_number_1']
      type_id = row['telephone_number_1_type_id'].to_i rescue 0
      patron.telephone_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row['telephone_number_2']
      patron.telephone_number_2 = row['telephone_number_2']
      type_id = row['telephone_number_2_type_id'].to_i rescue 0
      patron.telephone_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row['extelephone_number_1']
      patron.extelephone_number_1 = row['extelephone_number_1']
      type_id = row['extelephone_number_1_type_id'].to_i rescue 0
      patron.extelephone_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row['extelephone_number_2']
      patron.extelephone_number_2 = row['extelephone_number_2']
      type_id = row['extelephone_number_2_type_id'].to_i rescue 0
      patron.extelephone_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row['fax_number_1']
      patron.fax_number_1 = row['fax_number_1']
      type_id = row['fax_number_1_type_id'].to_i rescue 0
      patron.fax_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row['fax_number_2']
      patron.fax_number_2 = row['fax_number_2']
      type_id = row['fax_number_2_type_id'].to_i rescue 0
      patron.fax_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    patron.address_1_note = row['address_1_note'] if row['address_1_note']
    patron.address_2_note = row['address_2_note'] if row['address_1_note']
    patron.note = row['note'] if row['note']
    patron.note_update_at = row['note_update_at'] if row['note_update_at']
    patron.note_update_by = row['note_update_by'] if row['note_update_by']
    patron.note_update_library = row['note_update_library'] if row['note_update_library']
    patron.birth_date = row['birth_date'] if row['birth_date']
    patron.death_date = row['death_date'] if row['death_date']
    patron.patron_type_id = row['patron_type_id'] unless row['patron_type_id'].to_s.strip.blank?
    patron.url = row['url'].to_s.strip if row['url']
    patron.other_designation = row['other_designation'].to_s.strip if row['other_designation']
    patron.place = row['place'].to_s.strip if row['place']
    patron.email = row['email'].to_s.strip if row['email']

    if row['username'].to_s.strip.blank?
      #patron.email = row['email'].to_s.strip
      patron.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Guest')
    else
      patron.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Librarian')
    end
    language = Language.where(:name => row['language'].to_s.strip.camelize).first
    language = Language.where(:iso_639_2 => row['language'].to_s.strip.downcase).first unless language
    language = Language.where(:iso_639_1 => row['language'].to_s.strip.downcase).first unless language
    patron.language = language if language
    country = Country.where(:name => row['country'].to_s.strip).first
    patron.country = country if country
    patron.patron_identifier = row['patron_identifier'].to_s.strip if row['patron_identifier']
=end
    patron
  end

  def set_user_value(user, row)
#日本語化
      username = I18n.t('activerecord.attributes.user.username')
      user_number = I18n.t('activerecord.attributes.user.user_number')
      library = I18n.t('activerecord.attributes.user.library')
      user_group_name = I18n.t('activerecord.attributes.user.user_group')
      department = I18n.t('activerecord.attributes.user.department')
      expired_at = I18n.t('activerecord.attributes.user.expired_at')
      status = I18n.t('activerecord.attributes.user.user_status')
      unable = I18n.t('activerecord.attributes.user.unable')
      email = I18n.t('activerecord.attributes.patron.email')
      url = I18n.t('activerecord.attributes.patron.url')
      created_at = I18n.t('page.created_at')
      updated_at = I18n.t('page.updated_at')

    user.operator = User.find(1)

    email = row[email].to_s.strip
    if email.present?
      user.email = email
      user.email_confirmation = email
    end
    password = row['password'].to_s.strip
    if password.present?
      user.password = password
      user.password_confirmation = password
    end
    user.username = row[username] if row[username]
    user.user_number = row[user_number] if row[user_number]
    user.library = Library.where(:name => row[library].to_s.strip).first || Library.web
    user.user_group = UserGroup.where(:name => row[user_group_name]).first || UserGroup.first
    user.department = Department.where(:name => row[department]).first || Department.first
    user.expired_at = row[expired_at] if row[expired_at]
    user.user_status = UserStatus.where(:display_name => row[status]).first || UserStatus.first
    user.unable = row[unable] if row[unable]
    user.created_at = row[created_at]
    user.updated_at = row[updated_at]
    role = Role.where(:name => row['role_name'].to_s.strip.camelize).first || Role.find('User')
    user.role = role
    required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Librarian')
    user.required_role = required_role
    locale = Language.where(:iso_639_1 => row['locale'].to_s.strip).first
    user.locale = locale || I18n.default_locale.to_s

    #unless row['library_id'].to_s.strip.blank?
    #  user.library_id = row['library_id']
    #end

=begin
    email = row['email'].to_s.strip
    if email.present?
      user.email = email
      user.email_confirmation = email
    end
    password = row['password'].to_s.strip
    if password.present?
      user.password = password
      user.password_confirmation = password
    end
    user.username = row['username'] if row['username']
    user.user_number = row['user_number'] if row['user_number']
    user.library = Library.where(:name => row['library'].to_s.strip).first || Library.web
    user.user_group = UserGroup.where(:name => row['user_group_name']).first || UserGroup.first
    user.department = Department.where(:name => row['department']).first || Department.first
    user.expired_at = row['expired_at'] if row['expired_at']
    user.user_status = UserStatus.where(:display_name => row['status']).first || UserStatus.first
    user.unable = row['unable'] if row['unable']
    user.created_at = row['created_at']
    user.updated_at = row['updated_at']
    role = Role.where(:name => row['role_name'].to_s.strip.camelize).first || Role.find('User')
    user.role = role
    required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Librarian')
    user.required_role = required_role
    locale = Language.where(:iso_639_1 => row['locale'].to_s.strip).first
    user.locale = locale || I18n.default_locale.to_s

    unless row['library_id'].to_s.strip.blank?
      user.library_id = row['library_id'] 
    end
=end
    user
  end
end

# == Schema Information
#
# Table name: patron_import_files
#
#  id                         :integer         not null, primary key
#  parent_id                  :integer
#  content_type               :string(255)
#  size                       :integer
#  file_hash                  :string(255)
#  user_id                    :integer
#  note                       :text
#  imported_at                :datetime
#  state                      :string(255)
#  patron_import_file_name    :string(255)
#  patron_import_content_type :string(255)
#  patron_import_file_size    :integer
#  patron_import_updated_at   :datetime
#  created_at                 :datetime
#  updated_at                 :datetime
#  edit_mode                  :string(255)
#

