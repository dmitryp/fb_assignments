class User < ActiveRecord::Base
  has_many :assignments
  
  def self.for(facebook_user)
    find_or_create_by_facebook_id(facebook_user.id)
  end
end
