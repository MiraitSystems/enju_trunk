module ActiveRecordExtension
  def attr_keycode_accessor(*args)
    args.each do |arg|
      class_eval <<-EOF
        attr_accessible :#{arg}_id
        def #{arg}_id=(obj)
          if exinfo = #{self.name.underscore}_exinfos.where(:name => '#{arg}').first
            exinfo.update_attributes(:value => obj)
          else
            self.#{self.name.underscore}_exinfos.build(:name => '#{arg}', :value => obj)
          end
        end
        def #{arg}
          Keycode.find(#{self.name.underscore}_exinfos.where(:name => '#{arg}').first.value) rescue nil
        end
        def #{arg}_id
          #{arg}.try(:id)
        end
      EOF
    end
  end
end
