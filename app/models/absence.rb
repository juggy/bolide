# == Schema Information
# Schema version: 20090408154321
#
# Table name: absences
#
#  id          :integer(4)      not null, primary key
#  employee_id :integer(4)      
#  start_date  :date            
#  end_date    :date            
#  days        :float           
#  reason_id   :integer(4)      
#  justified   :boolean(1)      default(TRUE)
#  note        :string(255)     
#  created_at  :datetime        
#  updated_at  :datetime        
#

class Absence < ScopedByAccount
  belongs_to :contact, :class_name => "Contact", :foreign_key => "employee_id"
  belongs_to :reason, :class_name => "AbsenceType", :foreign_key => "reason_id"
  
  validates_presence_of :employee_id, :reason_id, :days, :start_date
  
  attr_accessor :status # TODO: remove temp hack
end
