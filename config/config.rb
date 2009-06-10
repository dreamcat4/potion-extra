
PE_PATH="#{File.join(File.dirname(__FILE__), '../')}"
# PE_PATH="#{RAILS_ROOT}/vendor/gems/potion-extra-0.1.1"
# PE_PATH="#{RAILS_ROOT}/vendor/gems/potion-extra"

def potion_extra_in_config 
  # return Proc.new {  
    return Proc.new { |config| 
      # Rails::Initializer.run do |config|      
      
      config.plugin_paths = ["#{PE_PATH}/vendor/plugins","#{RAILS_ROOT}/vendor/plugins"]
      config.gem_paths = ["#{PE_PATH}/vendor/gems"]
      
      config.gem "libxml-bindings"
      
      # config.reload_plugins = true
      # puts "hi we are in #{__FILE__}"
    }
end

def potion_extra_end_config
    return Proc.new {  
      # Include your application configuration below
      puts "#{PE_PATH}"

      # Remove trailing slash from URIs reaching Sinatra
      before { request.env['PATH_INFO'].gsub!(/\/$/, '') if request.env['PATH_INFO'] != '/' }

      # Preload controllers with Sinatra code
      require "#{PE_PATH}/app/controllers/qbwc_api_controller.rb"
    }
end

