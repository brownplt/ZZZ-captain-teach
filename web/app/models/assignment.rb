require 'digest/md5'
require 'uuidtools'

class Assignment < ActiveRecord::Base

  before_create :add_uid
  
  belongs_to :path_ref

  belongs_to :course

  validates_presence_of :path_ref
  
  private

  def add_uid()
    self.uid = Digest::MD5.hexdigest(UUIDTools::UUID.random_create.to_s)
  end
  
end
