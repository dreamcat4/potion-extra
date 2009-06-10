
PE_PATH="#{File.join(File.dirname(__FILE__), '../')}"

module PotionExtra

  def self.in_config
    return Proc.new do |config|

      # Rails::Initializer.run do |config|
      config.plugin_paths = ["#{PE_PATH}/vendor/plugins","#{RAILS_ROOT}/vendor/plugins"]
      config.gem_paths = ["#{PE_PATH}/vendor/gems"]

      config.gem "geokit"
      config.gem "sinatra"
      config.gem "libxml-bindings"

    end
  end

  def self.end_config
    return Proc.new do
      # Include your application configuration below
      # End of config/environment.rb

      # Remove trailing slash from URIs reaching Sinatra
      before { request.env['PATH_INFO'].gsub!(/\/$/, '') if request.env['PATH_INFO'] != '/' }

      # Preload controllers with Sinatra code
      require "#{PE_PATH}/app/controllers/qbwc_api_controller.rb"
    end
  end

end
