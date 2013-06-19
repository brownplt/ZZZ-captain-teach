# Load the rails application.
require File.expand_path('../application', __FILE__)

require File.expand_path('../../lib/commands.rb', __FILE__)
require File.expand_path('../../lib/scribble.rb', __FILE__)

# Initialize the rails application.
App::Application.initialize!

ASSIGNMENTS_PATH = File.expand_path("../../../src/assignments/", __FILE__)

