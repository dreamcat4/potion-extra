class Sinatra::Reloader < Rack::Reloader
  def safe_load(file, mtime, stderr = $stderr)
    if file == Sinatra::Application.app_file
      ::Sinatra::Application.reset!
      stderr.puts "#{self.class}: reseting routes"
    end
    super
  end
end


if defined? Sinatra::Application
  Sinatra::Application.set :reload, true
  # Sinatra::Application.set :logging, false
  # Sinatra::Application.set :raise_errors, true
  # Sinatra::Application
end
