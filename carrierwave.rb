# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'

gem 'rails', '#{Rails.version}'

gem 'rb-readline'
gem 'jbuilder', '~> 2.0'
gem 'sass-rails', '~> 5.0'
gem 'puma'
gem 'uglifier'
gem 'turbolinks', '~> 5'
gem 'carrierwave', '~> 1.0'
group :development, :test do
  gem 'byebug', platform: :mri
  gem 'sqlite3'
  gem 'rspec-rails'
end
group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rails-erd'
end
group :production do
  gem 'pg'
  gem 'rails_12factor'
end
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
RUBY

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

# Assets
########################################
run 'rm app/assets/stylesheets/*'
file 'app/assets/stylesheets/application.scss'

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
  //= require_tree .
JS

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Environment variables
########################################
file 'config/local_env.yml', <<-YAML
  KEY: VALUE
YAML
run 'rm config/application.rb'
file 'config/application.rb', <<-RUBY
  require_relative 'boot'
  require 'rails/all'
  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(*Rails.groups)

  module Tradfood
    class Application < Rails::Application
      # Load local_env.yml file - server vars
      config.before_configuration do
        env_file = File.join(Rails.root, 'config', 'local_env.yml')
        YAML.load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value
        end if File.exists?(env_file)
      end
    end
  end
RUBY

# Layout
########################################
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <title><%= meta_title %></title>
      <meta name="description" content="<%= meta_description %>">

      <!-- Facebook Open Graph data -->
      <meta property="og:title" content="<%= meta_title %>" />
      <meta property="og:type" content="website" />
      <meta property="og:url" content="<%= request.original_url %>" />
      <meta property="og:image" content="<%= meta_image %>" />
      <meta property="og:description" content="<%= meta_description %>" />
      <meta property="og:site_name" content="<%= meta_title %>" />

      <!-- Twitter Card data -->
      <meta name="twitter:card" content="summary_large_image">
      <meta name="twitter:site" content="<%= DEFAULT_META["twitter_account"] %>">
      <meta name="twitter:title" content="<%= meta_title %>">
      <meta name="twitter:description" content="<%= meta_description %>">
      <meta name="twitter:creator" content="<%= DEFAULT_META["twitter_account"] %>">
      <meta name="twitter:image:src" content="<%= meta_image %>">
      <%= csrf_meta_tags %>
      <%= action_cable_meta_tag %>
      <%= stylesheet_link_tag 'application', media: 'all' %>
    </head>
    <body>
      <%= yield %>
      <%= javascript_include_tag 'application' %>
    </body>
  </html>
HTML

# Cover page
########################################
run 'rm app/controllers/application_controller.rb'
file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # GET /
  def home
  end

  # Get main URL
  def default_url_options
    { host: ENV['HOST'] || 'localhost:3000' }
  end

end
RUBY

run 'mkdir app/views/application'
file 'app/views/application/home.html.erb', <<-HTML
  <% content_for :meta_title, "YOUR PAGE TITLE" %>
  <% content_for :meta_description, "YOUR PAGE DESCRIPTION" %>
  <% content_for :meta_image, "YOUR PAGE IMAGE" %>

  <h1>Hello !</h1>
  <h2>Welcome on your new Rails application !</h2>
HTML

# Meta tags
########################################
meta_file_content = <<-YAML
  meta_product_name: "APPLICATION NAME"
  meta_title: "TITLE DISPLAYED IN TOP OF BROWSER"
  meta_description: "DESCRIPTION"
  meta_image: ""
  twitter_account: "@TWITTER ACCOUNT"
YAML
file 'config/meta.yml', meta_file_content

file 'config/initializers/default_meta.rb', <<-RUBY
  # Initialize default meta tags.
  DEFAULT_META = YAML.load_file(Rails.root.join("config/meta.yml"))
RUBY

file 'app/helpers/meta_tags_helper.rb', <<-RUBY
  module MetaTagsHelper
    def meta_title
      content_for?(:meta_title) ? content_for(:meta_title) : DEFAULT_META["meta_title"]
    end

    def meta_description
      content_for?(:meta_description) ? content_for(:meta_description) : DEFAULT_META["meta_description"]
    end

    def meta_image
      meta_image = (content_for?(:meta_image) ? content_for(:meta_image) : DEFAULT_META["meta_image"])
    end
  end
RUBY

# README
########################################
markdown_file_content = <<-MARKDOWN
  # App
  Please, write the README !

  ## Rails template
  This app use the Bastien Robert Rails'template : [Bastien Robert](https://github.com/bastienrobert).
MARKDOWN
file 'README.md', markdown_file_content, force: true

########################################
# AFTER BUNDLE
########################################
after_bundle do

  # Stop spring
  ########################################
  run 'spring stop'

  # Carrierwave
  ########################################
  run 'rails g uploader Image'

  # Routes
  ########################################
  route "root to: 'application#home'"

  # Git ignore
  ########################################
  run 'rm .gitignore'
  file '.gitignore', <<-TXT
    .bundle
    log/*.log
    tmp/**/*
    tmp/*
    *.swp
    .DS_Store
    public/assets
    config/local_env.yml
  TXT

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit with kickstart -> https://github.com/bastienrobert/rails-template'"
end
