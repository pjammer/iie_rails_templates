# Choose the framework and add gems if needed:

base_layout = ask("Which front end framework [f]oundation, [b]ootstrap or [r]esponsive?")

if base_layout == "f"
  layout_gem_name = "foundation-rails"
  gem layout_gem_name
elsif base_layout == "b"
  gem 'therubyracer'
  gem "less-rails"
  gem "twitter-bootstrap-rails"
end
using_devise = yes?("Are we going to add Devise gem?")
gem("devise") if using_devise
#run bundle to get the latests gems
run "bundle"

#finish up any framework business
if base_layout == "f"
  generate("foundation:install")
end

# probably should put a recursive auto generating scaffold method here that takes two asks and then asks 'add another':
generate :controller, "Site index contact"

#setup root route
route "root to: 'site#index'"
#Devise and friends?
if using_devise
  generate "devise:install"
  generate :devise, 'User'
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: "development"
  gsub_file('config/routes.rb', /devise_for :users/, 'devise_for :users, :path => ""')
  #add first and last name
  generate :migration, "AddNameColumnsToUsers first_name:string last_name:string"
  #this should work why it no do.
  #gsub_file('test/fixtures/users.yml', /email:/, "email: sam#{(0..1000).to_a.sample}@blah.com")
  # What about Facebook?
  if yes?("Use Facebook with Devise too?")
    gem 'omniauth-facebook'
    run "bundle"
    #inject facebook provider into devise
    inject_into_file 'app/models/user.rb', :before => "end"  do
      "devise :omniauthable, :omniauth_providers => [:facebook]\n"
    end
    gsub_file('config/routes.rb', /devise_for :users/, 'devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }')
    generate :migration, "AddProviderColumnsToUsers provider:string uid:string"
    inject_into_file 'config/initializers/devise.rb', :after => "Devise.setup do |config|"  do
      "config.omniauth :facebook, 'APP_ID', 'APP_SECRET'\n"
    end
    #add a controller
    file 'app/controllers/users/omniauth_callbacks_controller.rb', <<-EOS
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end
EOS

    inject_into_file 'app/models/user.rb', before: "end" do
  "  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    user.email = auth.info.email
    user.password = Devise.friendly_token[0,20]
    #user.name = auth.info.name   # assuming the user model has a name
    #user.image = auth.info.image # assuming the user model has an image
  end
end\n"
    end

  end

  #Put all the devise views so you can muck around with them. Say no if you don't care.
  generate "devise:views" if yes?("Do you want the Devise Views to customize?")

  #remove user fixture and put this in place maybe?
  user_fixture_path = 'test/fixtures/users.yml'
  remove_file user_fixture_path
  file user_fixture_path, <<-EOS
DEFAULTS: &DEFAULTS
  first_name: $LABEL
  last_name: $LABEL
  email: $LABEL@$LABEL.com
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password01') %>

# Read about fixtures at http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html

one:
  <<: *DEFAULTS

two:
  <<: *DEFAULTS
EOS

else
  # genreate a User scaffold here
  generate(:scaffold, "User first_name:string last_name:string email:string password:string")
end
# May need to have Users with Accounts
if acct = yes?("Create Accounts for Users?")
  generate(:scaffold, "Account name:string user:references")
end
#if you have a cart you have a product to add; should add a "What do you call your product" save name to add as reference here.
if yes?("Create a Cart?")
  generate(:scaffold, "Cart #{acct ? "account" : "user"}:references")
  generate(:model, "CartItem cart:references")
end

# db create and migrate
rake "db:create"
rake "db:migrate"

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
