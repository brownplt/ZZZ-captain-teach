class InboxReadEvent < ActiveRecord::Base
  belongs_to :user
end
