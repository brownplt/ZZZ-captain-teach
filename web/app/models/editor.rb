class Editor < ActiveRecord::Base
  belongs_to :path_ref

  before_create :add_uid

  private

  def add_uid()
    self.uid = Digest::MD5.hexdigest(UUIDTools::UUID.random_create.to_s)
  end

  
end
