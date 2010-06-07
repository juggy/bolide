# == Schema Information
# Schema version: 20090408154321
#
# Table name: roles
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)     
#  description :string(255)     
#  category    :string(255)     
#

class Role < ScopedByAccount
  
  has_many :role_memberships
  has_many :users, :through => :role_memberships
  
  named_scope :active
  
  def self.users_with_role(role)
    self.find_by_name(role).users.active
  end
end
