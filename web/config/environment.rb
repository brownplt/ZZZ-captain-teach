# Load the rails application.
require File.expand_path('../application', __FILE__)

require File.expand_path('../../lib/commands.rb', __FILE__)
require File.expand_path('../../lib/scribble.rb', __FILE__)
require File.expand_path('../../lib/resources.rb', __FILE__)
require File.expand_path('../../lib/review.rb', __FILE__)

# Initialize the rails application.
App::Application.initialize!

ASSIGNMENTS_PATH = File.expand_path("../../../ct-assignments/", __FILE__)

DEFAULT_GIT_USER = {email: "", name: "Edward Teach"}

USER_GIT_REPO_PATH = File.expand_path("../../../user-repos/", __FILE__)

REVIEWS_SUBPATH = "reviews"
