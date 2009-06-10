# desc "Explaining what the task does"
# task :potion_extra do
#   # Task goes here
# end

namespace :potion_extra do
  
  desc "Sync the plugin db migration files to RAILS_ROOT/db"
  task :sync do
    system "rsync -ruv vendor/plugins/potion_extra/db/migrate db"
  end
  
  desc "Initialize main potionstore from this plugin"
  task :init do
    # eg Insert configuration lines to the environment.rb
    puts "Rake task stub (did nothing)."
    # task copy, config, sync, migrate, etc
  end
  
end

