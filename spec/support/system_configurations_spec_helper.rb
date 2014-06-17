# SystemConfigurationの簡易設定
def update_system_configuration(key, value)
  Rails.cache.clear
  sc = SystemConfiguration.find_by_keyname(key)
  unless sc
    t = case value
        when String
          'String'
        when true, false
          'Boolean'
        when Fixnum
          'Numeric'
        end
    sc = SystemConfiguration.new(keyname: key, typename: t)
  end
  sc.v = value.to_s
  sc.save!
end

# SystemConfigurationのstub
def stub_system_configuration(hash = {})
  unless defined?(@__system_configuration)
    @__system_configuration = {}
    SystemConfiguration.stub(:get) do |name|
      if @__system_configuration.include?(name)
        @__system_configuration[name]
      else
        raise "unexpected system configuration name `#{name}' for the stub"
      end
    end
  end
  @__system_configuration.merge!(hash)
end

def add_system_configuration(hash)
  unless defined?(@__system_configuration)
    stub_system_configuration
  end
  hash.each do |key, value|
    @__system_configuration[key] = value
  end
end
