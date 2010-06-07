# == Schema Information
# Schema version: 20090408154321
#
# Table name: role_memberships
#
#  id      :integer(4)      not null, primary key
#  user_id :integer(4)      
#  role_id :integer(4)      
#

class RoleMembership < ScopedByAccount
  
  belongs_to :user
  belongs_to :role
  
end
