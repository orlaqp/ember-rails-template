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

# modify scaffold_controller generator 
create_file 'lib/templates/rails/scaffold_controller/controller.rb', <<-CODE

<% if namespaced? -%>
require_dependency "<%= namespaced_file_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  respond_to :json

  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]

  # GET <%= route_url %>
  def index
    respond_with @<%= plural_table_name %> = <%= orm_class.all(class_name) %>
  end

  # GET <%= route_url %>/1
  def show
    respond_with @<%= singular_table_name %>
  end

  # GET <%= route_url %>/new
  def new
    respond_with @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
    respond_with @<%= singular_table_name %>
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, singular_table_name + "_params") %>

    if @<%= orm_instance.save %>
      render action: 'show', status: :created, location: @<%= singular_table_name %> 
    else
      render json: { errors: @<%= singular_table_name %>.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update(singular_table_name + "_params") %>
      head :no_content
    else
      render json: { errors: @<%= singular_table_name %>.errors }, status: :unprocessable_entity
    end
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    head :no_content 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    end

    # Only allow a trusted parameter "white list" through.
    def <%= singular_table_name + "_params" %>
      <%- if attributes_names.empty? -%>
      params[<%= ":" + singular_table_name %>]
      <%- else -%>
      params.require(<%= ":" + singular_table_name %>).permit(<%= attributes_names.map { |name| ":" + name }.join(', ') %>)
      <%- end -%>
    end
end
<% end -%>

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

application "# Sets ember's application name\n     config.ember.app_name='#{app_name}'"

application <<-CODE
    # customize scaffold generator to aoivd the creation of unnecesary code
    config.generators do |g|
      g.orm             :active_record
      g.template_engine false
      g.jbuilder        false
      g.helper          false
      g.test_framework  false
      g.stylesheets     false
    end
CODE

# generate ember bootstrap with support for ember script
generate "ember:bootstrap --javascript-engine=em"

# I need to inject jquery into application.js.em because it is not included by default by ember bootstrap geenerator
inject_into_file "app/assets/javascripts/application.js.em", "#= require jquery\n#= require moment\n#= require bootstrap\n", :before => "#= require handlebars\n"

# prepare application style
remove_file 'app/assets/stylesheets/application.css'
file 'app/assets/stylesheets/application.css.scss', <<-CODE
/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
 * or vendor/assets/stylesheets of plugins, if any, can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the top of the
 * compiled file, but it's generally better to create a new file per style scope.
 *
 *= require_self
 *= require_tree .
 */
 
@import "font-awesome";
@import "bootstrap";

CODE


# prepare emberjs store to use ActiveModelSerializer
gsub_file 'app/assets/javascripts/store.js.em', /adapter: '_ams'/, 'adapter: ''DS.ActiveModelAdapter'''

# ask the user if he/she wants the latest version of ember/ember-data
if yes?("Do you want to install the latest builds of ember and ember-data (y/N)?")
  generate "ember:install"
end


# generate git repository
git :init
git add: "."
git commit: %Q{ -m "Initial Commit" }


