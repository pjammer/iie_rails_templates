# Choose the framework and add gems if needed:

base_layout = ask("Which front end framework [f]oundation, [b]ootstrap or [r]esponsive?")

if base_layout == "f"
  layout_gem_name = "foundation-rails"
  gem layout_gem_name
elsif base_layout == "b"
  gem "less-rails"
  gem "twitter-bootstrap-rails"
end

#run bundle to get the latests gems
run "bundle"

#finish up any framework business
if base_layout == "f"
  generate("foundation:install")
end

# probably should put a recursive auto generating scaffold method here that takes two asks and then asks 'add another':
generate :controller, "Site index contact"
generate(:scaffold, "User first_name:string last_name:string")

#setup root route and db create and migrate
route "root to: 'site#index'"
rake "db:create"
rake "db:migrate"

# git :init
# git add: "."
# git commit: %Q{ -m 'Initial commit' }
