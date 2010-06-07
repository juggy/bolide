# == Schema Information
# Schema version: 20090408154321
#
# Table name: competence_audits
#
#  id            :integer(4)      not null, primary key
#  competence_id :integer(4)      
#  course_date   :date            
#  expires_on    :date            
#  created_at    :datetime        
#  updated_at    :datetime        
#

class CompetenceAudit < ScopedByAccount
  belongs_to :competence
end
