class AgentImportFile < ActiveRecord::Base
  attr_accessible :agent_import, :edit_mode
  include ImportFile
  default_scope :order => 'id DESC'
  scope :not_imported, where(:state => 'pending', :imported_at => nil)
  scope :stucked, where('created_at < ? AND state = ?', 1.hour.ago, 'pending')

  if Setting.uploaded_file.storage == :s3
    has_attached_file :agent_import, :storage => :s3, :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => "agent_import_files/:id/:filename",
      :s3_permissions => :private
  else
    has_attached_file :agent_import, :path => ":rails_root/private:url"
  end
  validates_attachment_content_type :agent_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/vnd.ms-excel'], :unless => proc{ SystemConfiguration.get("set_output_format_type") }
  validates_attachment_content_type :agent_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/octet-stream'], :if => proc{ SystemConfiguration.get("set_output_format_type") }
  validates_attachment_presence :agent_import
  belongs_to :user, :validate => true
  has_many :agent_import_results

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
    if File.exists?(agent_import.queued_for_write[:original])
      self.file_hash = Digest::SHA1.hexdigest(File.open(agent_import.queued_for_write[:original].path, 'rb').read)
    end
  end

  def import
    sm_start!
    #日本語化
    full_name = I18n.t('activerecord.attributes.agent.full_name')
    username = I18n.t('activerecord.attributes.user.username')
    del_flg = I18n.t('resource_import_textfile.excel.book.del_flg')
    library = I18n.t('activerecord.attributes.user.library')
    department = I18n.t('activerecord.attributes.user.department')

    self.reload
    num = {:agent_imported => 0, :user_imported => 0, :failed => 0}
    row_num = 2
    rows = open_import_file
    field = rows.first
    if [field[username], field[full_name], field[department]].reject{|field| field.to_s.strip == ""}.empty?
      raise "You should specify #{username} and #{full_name} in the first line"
    end
    rows.each do |row|
      next if row['dummy'].to_s.strip.present?
      begin
        if SystemConfiguration.get("set_output_format_type") == false
          import_result = AgentImportResult.create!(:agent_import_file => self, :body => row.fields.join(","))
        else
          import_result = AgentImportResult.create!(:agent_import_file => self, :body => row.fields.join("\t"))
        end

        department = row[department].first if row[department]
        if department.blank?
          import_result.error_msg = "FAIL[#{row_num}]: #{I18n.t('import.check_input')}"
          Rails.logger.info("update failed: column #{row_num}")
          num[:failed] += 1
          next
        end
        #delete_flagの定義
        delete_flag = row[del_flg].to_s.strip if row[del_flg]
        user = User.where(:username => row[username].to_s.strip).first
        #削除
        unless delete_flag.nil? or delete_flag.blank? or delete_flag.upcase == 'FALSE' or delete_flag.upcase == 'DELETE'
          if user.blank?
            import_result.error_msg = "FAIL[#{row_num}]: #{I18n.t('import.user_does_not_exist')}"
            next
          end

          User.transaction do
            import_result.error_msg = I18n.t('controller.successfully_deleted', :model => "#{user.agent.full_name}(#{user.username})")
            user.agent.destroy
            user.destroy
            num[:agent_imported] += 1
            num[:user_imported] += 1
          end
        else
          #作成
          if user.blank? 
            User.transaction do
              agent = Agent.new
              agent = set_agent_value(agent, row)
              user = User.new
              user.agent = agent
              set_user_value(user, row)
              if user.password.blank?
                user.set_auto_generated_password
              end
              if user.save!
                import_result.user = user
              end
              if agent.save!
                import_result.agent = agent
                num[:agent_imported] += 1
                if row_num % 50 == 0
                  Sunspot.commit
                  GC.start
                end
              end
              import_result.error_msg = I18n.t('import.successfully_created')
              num[:user_imported] += 1
            end
          else
            #更新
            if user.try(:agent)
              User.transaction do
                agent = set_agent_value(user.agent, row)
                set_user_value(user, row)
                if agent.save!
                  import_result.agent = agent
                end
                if user.save!
                  import_result.user = user
                end
                import_result.error_msg = I18n.t('import.successfully_updated')
                num[:user_imported] += 1
              end
            end
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        import_result.error_msg = "FAIL[#{row_num}]: #{e}"
        Rails.logger.info("update failed: column #{row_num}")
        num[:failed] += 1
        next
      ensure
        import_result.save!
        row_num += 1
      end
    end
    self.update_attribute(:imported_at, Time.zone.now)
    Sunspot.commit
    rows.close
    sm_complete!
    return num
  end

  def self.import(id = nil)
    #AgentImportFile.not_imported.each do |file|
    #  file.import_start
    #end
    if !id.nil?
      file = AgentImportFile.find(id) rescue nil
      file.import unless file.nil?
    else
      AgentImportFile.not_imported.each do |file|
        file.import
      end
    end
  rescue
    logger.error "#{Time.zone.now} importing agents failed!"
    logger.error $@
  end

  private
  def open_import_file
    tempfile = Tempfile.new('agent_import_file')
    if Setting.uploaded_file.storage == :s3
      uploaded_file_path = open(self.agent_import.expiring_url(10)).path
    else
      uploaded_file_path = self.agent_import.path
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
      AgentImportResult.create(:agent_import_file => self, :body => header.join(","), :error_msg => 'HEADER DATA')
    else
      AgentImportResult.create(:agent_import_file => self, :body => header.join("\t"), :error_msg => 'HEADER DATA')
    end
    tempfile.close(true)
    file.close
    rows
  end

  def set_agent_value(agent, row)
    #日本語化
    full_name = I18n.t('activerecord.attributes.agent.full_name')
    full_name_transcription = I18n.t('activerecord.attributes.agent.full_name_transcription')
    full_name_alternative = I18n.t('activerecord.attributes.agent.full_name_alternative')
    first_name = I18n.t('activerecord.attributes.agent.first_name')
    first_name_transcription = I18n.t('activerecord.attributes.agent.first_name_transcription')
    last_name = I18n.t('activerecord.attributes.agent.last_name')
    last_name_transcription = I18n.t('activerecord.attributes.agent.last_name_transcription')
    username = I18n.t('activerecord.attributes.user.username')
    agent_type = I18n.t('activerecord.models.agent_type')
    url = I18n.t('activerecord.attributes.agent.url')
    email = I18n.t('activerecord.attributes.agent.email')
    grade = I18n.t('activerecord.attributes.agent.grade')
    other_designation = I18n.t('activerecord.attributes.agent.other_designation')
    place = I18n.t('activerecord.attributes.agent.place')
    language = I18n.t('activerecord.models.language')
    country = I18n.t('activerecord.models.country')
    zip_code_1 = I18n.t('activerecord.attributes.agent.zip_code_1')
    address_1 = I18n.t('activerecord.attributes.agent.address_1')
    telephone_number_1 = I18n.t('activerecord.attributes.agent.telephone_number_1')
    telephone_number_1_type_id = I18n.t('activerecord.attributes.agent.telephone_number_1_type')
    extelephone_number_1 = I18n.t('activerecord.attributes.agent.extelephone_number_1')
    extelephone_number_1_type_id = I18n.t('activerecord.attributes.agent.extelephone_number_1_type')
    fax_number_1 = I18n.t('activerecord.attributes.agent.fax_number_1')
    fax_number_1_type_id = I18n.t('activerecord.attributes.agent.fax_number_1_type')
    address_1_note = I18n.t('activerecord.attributes.agent.address_1_note')
    zip_code_2 = I18n.t('activerecord.attributes.agent.zip_code_2')
    address_2 = I18n.t('activerecord.attributes.agent.address_2')
    telephone_number_2 = I18n.t('activerecord.attributes.agent.telephone_number_2')
    telephone_number_2_type_id = I18n.t('activerecord.attributes.agent.telephone_number_2_type')
    extelephone_number_2 = I18n.t('activerecord.attributes.agent.extelephone_number_2')
    extelephone_number_2_type_id = I18n.t('activerecord.attributes.agent.extelephone_number_2_type')
    fax_number_2 = I18n.t('activerecord.attributes.agent.fax_number_2')
    fax_number_2_type_id = I18n.t('activerecord.attributes.agent.fax_number_2_type')
    address_2_note = I18n.t('activerecord.attributes.agent.address_2_note')
    birth_date = I18n.t('activerecord.attributes.agent.date_of_birth')
    death_date = I18n.t('activerecord.attributes.agent.date_of_death')
    note = I18n.t('activerecord.attributes.agent.note')
    note_update_at = I18n.t('activerecord.attributes.agent.note_update_at')
    note_update_by = I18n.t('activerecord.attributes.agent.note_update_by')
    note_update_library = I18n.t('activerecord.attributes.agent.note_update_library')
    agent_identifier = I18n.t('agent.agent_identifier')

    agent.first_name = row[first_name] if row[first_name]
    agent.last_name = row[last_name] if row[last_name]
    agent.first_name_transcription = row[first_name_transcription] if row[first_name_transcription]
    agent.last_name_transcription = row[last_name_transcription] if row[last_name_transcription]

    agent.full_name = row[full_name] if row[full_name]
    agent.full_name_transcription = row[full_name_transcription] if row[full_name_transcription]
    agent.full_name_alternative = row[full_name_alternative] if row[full_name_alternative]

    agent.address_1 = row[address_1] if row[address_1]
    agent.address_2 = row[address_2] if row[address_2]
    agent.zip_code_1 = row[zip_code_1] if row[zip_code_1]
    agent.zip_code_2 = row[zip_code_2] if row[zip_code_2]
 
    if row[telephone_number_1]
      agent.telephone_number_1 = row[telephone_number_1]
      type_id = row[telephone_number_1_type_id].to_i rescue 0
      agent.telephone_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[telephone_number_2]
      agent.telephone_number_2 = row[telephone_number_2]
      type_id = row[telephone_number_2_type_id].to_i rescue 0
      agent.telephone_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[extelephone_number_1]
      agent.extelephone_number_1 = row[extelephone_number_1]
      type_id = row[extelephone_number_1_type_id].to_i rescue 0
      agent.extelephone_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[extelephone_number_2]
      agent.extelephone_number_2 = row[extelephone_number_2]
      type_id = row[extelephone_number_2_type_id].to_i rescue 0
      agent.extelephone_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[fax_number_1]
      agent.fax_number_1 = row[fax_number_1]
      type_id = row[fax_number_1_type_id].to_i rescue 0
      agent.fax_number_1_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end
    if row[fax_number_2]
      agent.fax_number_2 = row[fax_number_2]
      type_id = row[fax_number_2_type_id].to_i rescue 0
      agent.fax_number_2_type_id = ((0 < type_id and type_id < 6) ? type_id : 1)
    end

    agent.address_1_note = row[address_1_note] if row[address_1_note]
    agent.address_2_note = row[address_2_note] if row[address_1_note]
    agent.note = row[note] if row[note]
    agent.note_update_at = row[note_update_at] if row[note_update_at]
    agent.note_update_by = row[note_update_by] if row[note_update_by]
    agent.note_update_library = row[note_update_library] if row[note_update_library]
    agent.birth_date = row[birth_date] if row[birth_date]
    agent.death_date = row[death_date] if row[death_date]
    agent.agent_type_id = row[agent_type] unless row[agent_type].to_s.strip.blank?
    agent.url = row[url].to_s.strip if row[url]
    agent.other_designation = row[other_designation].to_s.strip if row[other_designation]
    agent.place = row[place].to_s.strip if row[place]
    agent.email = row[email].to_s.strip if row[email]
    agent.grade = row[grade] if row[grade]

    if row[username].to_s.strip.blank?
      agent.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Guest')
    else
      agent.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Librarian')
    end
    language = Language.where(:name => row[language].to_s.strip.camelize).first || Language.find('77')
    language = Language.where(:iso_639_2 => row[language].to_s.strip.downcase).first unless language
    language = Language.where(:iso_639_1 => row[language].to_s.strip.downcase).first unless language
    agent.language = language if language
    country = Country.where(:name => row[country].to_s.strip).first
    agent.country = country if country
    agent.agent_identifier = row[agent_identifier].to_s.strip if row[agent_identifier]
    agent
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
    email = I18n.t('activerecord.attributes.agent.email')
    url = I18n.t('activerecord.attributes.agent.url')
    created_at = I18n.t('page.created_at')
    updated_at = I18n.t('page.updated_at')
    role = I18n.t('activerecord.models.role')

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
    unless SystemConfiguration.get("auto_user_number") == false
      user.user_number = row[username] if row[username]
    else
      user.user_number = row[user_number] if row[user_number]
    end
    # 所属図書館（未入力の場合：図書館が一つ以外はエラー　入力の場合：図書館が複数あり、入力ミスだとエラー）
    #library = row[library].first if row[library]
    unless library.blank?
      if Library.all.length == 1
        user.library = Library.where(:name => row[library].to_s.strip).first || Library.first
      else
        unless Library.where(:name => row[library].to_s.strip).first.blank? 
          user.library = Library.where(:name => row[library].to_s.strip).first
        else
          user.library = nil
        end
      end
    end
    user.user_group = UserGroup.where(:name => row[user_group_name]).first || UserGroup.first
    # 部署（未登録の場合、id = name 入力値 = displayname にて新規作成）
    if (Department.where(:display_name => row[department]).first).blank?
      unless row[department].blank?
        new_department = Department.add_department(row[department])
        logger.info(new_department)
        user.department = Department.where(:display_name => new_department).first
      end
    else
      user.department = Department.where(:display_name => row[department]).first
    end
    user.expired_at = row[expired_at] if row[expired_at]
    user.user_status = UserStatus.where(:display_name => row[status]).first || UserStatus.first
    user.unable = row[unable] if row[unable]
    user.created_at = row[created_at] if row[created_at]
    user.updated_at = row[updated_at] if row[updated_at]
    user.role = Role.where(:id => row[role].to_s.strip).first || Role.find('User')
    user.required_role = Role.where(:name => row['required_role_name'].to_s.strip.camelize).first || Role.find('Librarian')
    locale = Language.where(:iso_639_1 => row['locale'].to_s.strip).first
    user.locale = locale || I18n.default_locale.to_s


    #unless row['library_id'].to_s.strip.blank?
    #  user.library_id = row['library_id']
    #end

    user
  end
end

# == Schema Information
#
# Table name: agent_import_files
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
#  agent_import_file_name    :string(255)
#  agent_import_content_type :string(255)
#  agent_import_file_size    :integer
#  agent_import_updated_at   :datetime
#  created_at                 :datetime
#  updated_at                 :datetime
#  edit_mode                  :string(255)
#

