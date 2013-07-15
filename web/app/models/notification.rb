class Notification < ActiveRecord::Base
  belongs_to :user

  def to_json
    JSON.dump({
      message: self.message,
      action: JSON.parse(self.action)
    })
  end

end
