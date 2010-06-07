# == Schema Information
# Schema version: 20090408154321
#
# Table name: employee_infos
#
#  id              :integer(4)      not null, primary key
#  contact_id      :integer(4)      
#  address         :string(255)     
#  home_number     :string(255)     
#  cell_number     :string(255)     
#  birthday        :date            
#  urgency_contact :string(255)     
#  created_at      :datetime        
#  updated_at      :datetime        
#  prefered        :boolean(1)      
#  employee_number :string(255)     
#  hired_on        :date            
#  union           :string(255)     
#

class EmployeeInfo < ScopedByAccount
  belongs_to :contact
  belongs_to :level, :class_name => "EmployeeLevel", :foreign_key => "level_id"
  
  acts_as_commentable
end
