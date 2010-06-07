# == Schema Information
# Schema version: 20090408154321
#
# Table name: warranty_infos
#
#  id               :integer(4)      not null, primary key
#  project_id       :integer(4)      
#  warranty_type_id :integer(4)      
#  years            :integer(4)      
#  description      :text            
#  created_at       :datetime        
#  updated_at       :datetime        
#

class WarrantyInfo < ScopedByAccount
  belongs_to :project
  belongs_to :warranty_type
  
  validates_presence_of :project_id
  
  # used to discard the model with attribute_fu
  def blank?
    warranty_type_id.nil? && years.to_i == 0 && description.blank?
  end
  
  def to_s
    "#{warranty_type} #{years} ans - #{description}"
  end
end
