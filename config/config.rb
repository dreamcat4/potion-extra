PE_PATH="#{File.expand_path('../',File.dirname(__FILE__))}"

module PotionExtra
  
  # The next 3 methods are taken from gem alexch-rerun
  def self.app_name
    # todo: make sure this works in non-Mac and non-Unix environments
    File.expand_path(".").gsub(/^.*\//, '').capitalize
  end

  def self.growlcmd
    `which growlnotify`.chomp
  end

  def self.growl(title, body, icon=nil, background = true)
    icon = "--image \"#{icon}\"" if icon
    s = "#{growlcmd} -H localhost -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\" #{icon}"
    s += " &" if background
    `#{s}`
  end
  
  # This is a gem, but load it as a rails plugin too (for app/metal)
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
      
      # config.middleware.use Rack::Reloader, 2 
      # config.logger = Logger.new(STDOUT) config.logger = Log4r::Logger.new("Application Log")

      config.after_initialize do
        PotionExtra.growl "ready", "Rails is up an running!", "#{PE_PATH}/public/rails_grn_sml.png"
        # Launch qb_update_selected script
      end
      
      # The Dispatcher#to_prepare method is similar to Configuration#after_initialize, 
      # but is used to execute code before each request, rather than on app initialization.
      config.to_prepare do
        # SystemPaths.system_config_file = "#{RAILS_ROOT}/configs/system.yml" 
      end

    end
  end

  def self.end_config
    return Proc.new do
      # Include your application configuration below
      # End of config/environment.rb
      
      # ActiveRecord::Base.logger = Logger.new(STDOUT) ActiveRecord::Base.logger = Log4r::Logger.new("Application Log")      
    end
  end

end
