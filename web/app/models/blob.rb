class Blob < ActiveRecord::Base
  belongs_to :user

  before_create :add_uid

  validate :data_is_json
  
  private

  def add_uid()
    self.uid = Digest::MD5.hexdigest(UUIDTools::UUID.random_create.to_s)
  end

  def data_is_json
    errors[:base] << "Data isn't valid JSON: #{self.data}" unless
      JSON.is_json?(self.data)
  end
    
end
