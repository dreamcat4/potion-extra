PE_PATH="#{File.expand_path('../',File.dirname(__FILE__))}"

module PotionExtra
  
  RAILS_GEM_VERSION = '2.3.2'
  class PotionExtraLocator < Rails::Plugin::Locator
    def plugins
      Rails::Plugin.new "#{PE_PATH}"
    end
  end

  def self.pre_config
    return Proc.new do
      # Beginning of config/environment.rb
      # Before initializer run do |config|      
    end
  end

  def self.in_config
    return Proc.new do |config|
      # Rails::Initializer.run do |config|

      config.plugin_locators << PotionExtraLocator    
      config.plugin_paths = ["#{PE_PATH}/vendor/plugins","#{RAILS_ROOT}/vendor/plugins"]
      # config.reload_plugins = true

      config.gem_paths = ["#{PE_PATH}/vendor/gems"]
      config.gem "geokit"
      config.gem "sinatra"
      config.gem "libxml-bindings"
      config.gem "uuidtools"
      config.gem "state_machine"
      
      config.middleware.use Rack::Reloader, 2 
      
    end
  end

  def self.end_config
    return Proc.new do
      # Include your application configuration below
      # End of config/environment.rb
    end
  end

end
