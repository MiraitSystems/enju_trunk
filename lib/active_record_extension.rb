module ActiveRecordExtension
  def attr_keycode_accessor(*args)
    args.each do |arg|
      class_eval <<-EOF
        attr_accessible :#{arg}_id
        def #{arg}_id=(obj)
          if obj.blank?
            if exinfo = #{self.name.underscore}_exinfos.where(:name => '#{arg}').first
              exinfo.destroy
            end
          else
            if exinfo = #{self.name.underscore}_exinfos.where(:name => '#{arg}').first
              exinfo.update_attributes(:value => obj)
            else
              self.#{self.name.underscore}_exinfos.build(:name => '#{arg}', :value => obj)
            end
          end
          @#{arg}_id = obj
        end
        def #{arg}
          Keycode.find(#{self.name.underscore}_exinfos.where(:name => '#{arg}').first.value) rescue nil
        end
        def #{arg}_id
          if @#{arg}_id.nil?
            @#{arg}_id = #{arg}.try(:id)
          end
          return @#{arg}_id
        end
      EOF
    end
  end

  def attr_exinfo_accessor(*args)
    args.each do |arg|
      class_eval <<-EOF
        attr_accessible :#{arg}
        def #{arg}=(obj)
          if obj.blank?
            if extext = #{self.name.underscore}_exinfos.where(:name => '#{arg}').first
              extext.destroy
            end
          else
            if exinfo = #{self.name.underscore}_exinfos.where(:name => '#{arg}').first
              exinfo.update_attributes(:value => obj)
            else
              self.#{self.name.underscore}_exinfos.build(:name => '#{arg}', :value => obj)
            end
          end
          @#{arg} = obj
        end
        def #{arg}
          if @#{arg}.nil?
            @#{arg} = #{self.name.underscore}_exinfos.where(:name => '#{arg}').first.value rescue nil
          end
          return @#{arg}
        end
      EOF
    end
  end

  def attr_extext_accessor(*args)
    args.each do |arg|
      class_eval <<-EOF
        attr_accessible :#{arg}, :#{arg}_type_id
        def #{arg}=(obj)
          if obj.blank?
            if extext = #{self.name.underscore}_extexts.where(:name => '#{arg}').first
              extext.destroy
            end
          else
            if extext = #{self.name.underscore}_extexts.where(:name => '#{arg}').first
              extext.update_attributes(:value => obj)
            else
              self.#{self.name.underscore}_extexts.build(:name => '#{arg}', :value => obj)
            end
          end
          @#{arg} = obj
        end
        def #{arg}
          if @#{arg}.nil?
            @#{arg} = #{self.name.underscore}_extexts.where(:name => '#{arg}').first.value rescue nil
          end
          return @#{arg}
        end

        def #{arg}_type_id=(obj)
          unless obj.blank?
            if extext = #{self.name.underscore}_extexts.where(:name => '#{arg}').first
              extext.update_attributes(:type_id => obj)
            else
              self.#{self.name.underscore}_extexts.build(:name => '#{arg}', :type_id => obj)
            end
          end 
          @#{arg}_type_id = obj
        end
        def #{arg}_type_id
          if @#{arg}.nil?
            @#{arg}_type_id = #{self.name.underscore}_extexts.where(:name => '#{arg}').first.type_id rescue nil
          end
          return @#{arg}_type_id
        end
      EOF
    end
  end
end
