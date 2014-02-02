# Gems
gem 'bootstrap-sass', '~> 3.1.0'
gem 'compass-rails'
gem 'font-awesome-rails'

gem 'ember-rails'
gem 'ember-source', '1.3.0'
gem 'ember_script-rails'

# other useful gems
gem 'momentjs-rails'
gem 'annotate', ">=2.5.0"
gem "better_errors"

run "bundle install"

# Add ember variant selection
["development", "production"].each do |env|
  application(nil, :env => env) do
    "# Sets which variant of ember to include\n  config.ember.variant = :#{env}\n"
  end
end

generate :controller, "Assets", "index"
run "rm app/views/assets/index.html.erb"
file 'app/views/assets/index.html.erb', <<-CODE
<!DOCTYPE html>
<html>
<head>
  <title>#{@app_name.titleize}</title>
  <%= stylesheet_link_tag    "application", :media => "all" %>
  <%= csrf_meta_tags %>
</head>
<body>
  <%= javascript_include_tag "application" %>
</body>
</html>
CODE

remove_file 'app/assets/javascripts/application.js'
remove_file 'app/assets/javascripts/templates/application.handlebars'

file 'app/assets/javascripts/templates/application.handlebars', <<-CODE
<div style="width: 600px; border: 6px solid #eee; margin: 0 auto; padding: 20px; text-align: center; font-family: sans-serif;">
  <img src="http://emberjs.com/images/about/ember-productivity-sm.png" style="display: block; margin: 0 auto;">
  <h1>Welcome to Ember.js!</h1>
  <p>You're running an Ember.js app on top of Ruby on Rails. To get started, replace this content
  (inside <code>app/assets/javascripts/templates/application.handlebars</code>) with your application's
  HTML.</p>
</div>
CODE

run "rm -rf app/views/layouts"
route "root :to => 'assets#index'"

# Generate a default serializer that is compatible with ember-data
generate :serializer, "application", "--parent", "ActiveModel::Serializer"
inject_into_class "app/serializers/application_serializer.rb", 'ApplicationSerializer' do
  "  embed :ids, :include => true\n"
end

# Route / to app#index
# route("root to: 'app#index'")
remove_file 'public/index.html'

# ask for the ember application name
app_name = ask('Ember Application Name: (default: App)')
app_name = "App" unless not app_name.blank?

application "# Sets ember's application name\n  config.ember.app_name='#{app_name}'"

# generate ember bootstrap with support for ember script
generate "ember:bootstrap -g --javascript-engine=em"

# I need to inject jquery into application.js.em because it is not included by default by ember bootstrap geenerator
inject_into_file "app/assets/javascripts/application.js.em", "#= require jquery\n", :before => "#= require handlebars\n"


# generate git repository
git :init
git add: "."
git commit: %Q{ -m "Initial Commit" }


