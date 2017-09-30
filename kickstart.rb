require 'shellwords'
require 'tmpdir'

if __FILE__ =~ %r{\Ahttps?://}
  source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
  at_exit { FileUtils.remove_entry(tempdir) }
  git :clone => [
    "--quiet",
    "https://github.com/bastienrobert/rails-template.git",
    tempdir
  ].map(&:shellescape).join(" ")
else
  source_paths.unshift(File.dirname(__FILE__))
end

# GEMFILE
########################################
remove_file 'Gemfile'

run "touch Gemfile"
add_source 'https://rubygems.org'

gem 'rails', '~> 5.1'

gem 'rb-readline'
gem 'jbuilder', '~> 2.0'
gem 'sass-rails', '~> 5.0'
gem 'puma'
gem 'uglifier'
gem 'turbolinks', '~> 5'
gem_group :development, :test do
  gem 'byebug', platform: :mri
  gem 'sqlite3'
  gem 'rspec-rails'
end
gem_group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rails-erd'
end
gem_group :production do
  gem 'pg'
  gem 'rails_12factor'
end
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

use_devise = yes?("Would you like to add devise? (Y/n)")
gem "devise" if use_devise

use_carrierwave = yes?("Would you like to add carrierwave? (Y/n)")
gem 'carrierwave', '~> 1.0' if use_carrierwave

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Meta tags
########################################
template 'config/meta.yml.tt'
template 'config/initializers/default_meta.rb.tt'
template 'app/helpers/meta_tags_helper.rb.tt'

# Procfile
########################################
template 'Procfile.tt'

# Environment variables
########################################
template 'config/local_env.yml.tt'

run 'rm config/application.rb'
template 'config/application.rb.tt'

# Assets
########################################
run 'rm app/assets/stylesheets/*'
file 'app/assets/stylesheets/application.scss'

run 'rm app/assets/javascripts/application.js'
template 'app/assets/javascripts/application.js.tt'

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
run 'mkdir app/views/layouts/partials'
file 'app/views/layouts/partials/_header.html.erb'
file 'app/views/layouts/partials/_footer.html.erb'
run 'rm app/views/layouts/application.html.erb'
copy_file 'app/views/layouts/application.html.erb'

# Cover page
########################################
run 'rm app/controllers/application_controller.rb'
template 'app/controllers/application_controller.rb.tt'

run 'mkdir app/views/application'
template 'app/views/application/home.html.erb.tt'

# README
########################################
# Replace README.md
template "README.md.tt", :force => true

########################################
# AFTER BUNDLE
########################################
after_bundle do

  # Stop spring
  ########################################
  run 'spring stop'

  # Routes
  ########################################
  route "root to: 'application#home'"

  # Git ignore
  ########################################
  remove_file '.gitignore'
  copy_file '.gitignore'

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit with kickstart -> https://github.com/bastienrobert/rails-template'"

  # Using devise
  ########################################
  if use_devise
    run 'rails generate devise:install'
    run 'rails generate devise MODEL'
    run 'rails generate devise:views'

    git :init
    git add: '.'
    git commit: "-m 'Gem devise initialized & views has been generated'"
  end

  # Using carrierwave
  ########################################
  if use_carrierwave
    configure_carrierwave = yes?('Do you want to create a Carrierwave uploader now? (Y/n)')
    if configure_carrierwave
      puts "Set a name for your Carrierwave Uploader"
      carrierwave_model = ask('Uploader name (set blank for Image):')
      if carrierwave_model == '' || carrierwave_model == nil
        carrierwave_model = 'Image'
      end
      run "rails generate uploader #{carrierwave_model}"

      git :init
      git add: '.'
      git commit: "-m 'Carrierwave #{carrierwave_model} uploader generated'"
    end
  end
end
