# == Schema Information
# Schema version: 20090408154321
#
# Table name: courses
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)     
#  description :text            
#  deleted_at  :datetime        
#  created_at  :datetime        
#  updated_at  :datetime        
#

class Course < ScopedByAccount
  default_scope :order => 'name'
  validates_presence_of :name
  has_many :competences
  belongs_to :company
end
