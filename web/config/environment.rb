# Load the rails application.
require File.expand_path('../application', __FILE__)

require File.expand_path('../../lib/commands.rb', __FILE__)
require File.expand_path('../../lib/scribble.rb', __FILE__)
require File.expand_path('../../lib/resources.rb', __FILE__)

# Initialize the rails application.
App::Application.initialize!

REPOSITORY_PATH = File.expand_path("../../../", __FILE__)

ASSIGNMENTS_PATH = File.expand_path("../../../ct-assignments/", __FILE__)

DEFAULT_GIT_USER = {email: "", name: "Edward Teach"}

USER_GIT_REPO_PATH =
  File.join(File.expand_path("../../../user-repos/", __FILE__), Rails.env)

REVIEWS_SUBPATH = "reviews"


WHALESONG_URL = "http://localhost:8080"
APP_URL = "http://localhost:3000"

if(ENCRYPTION)
  CT_KEY = File.read(KEY_FILE).unpack('m')[0]
end

