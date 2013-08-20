class Submitted < ActiveRecord::Base
  belongs_to :user

  validates_format_of :known, :with => /\A(good|bad|unknown)\Z/

  def set_good
    self.known = "good"
  end

  def set_bad
    self.known = "bad"
  end

  def set_unknown
    self.known = "unknown"
  end

  def get_contents
    type,perm,ref,args,user = Resource::parse(self.resource)
    response = Resource::lookup(type,perm,ref,args,user)
    if response.is_a? Resource::Normal
      @contents = response.data
    else
      @contents = ""
    end
  end

end
