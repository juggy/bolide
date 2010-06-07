# == Schema Information
# Schema version: 20090408154321
#
# Table name: activities
#
#  id                   :integer(4)      not null, primary key
#  type                 :string(255)     
#  user_id              :integer(4)      
#  party_id             :integer(4)      
#  title                :string(255)     
#  body                 :text            
#  scheduled_at         :datetime        
#  created_at           :datetime        
#  updated_at           :datetime        
#  closed_at            :datetime        
#  activity_category_id :integer(4)      
#  private              :boolean(1)      
#  project_id           :integer(4)      
#  message_sender       :string(255)     
#  position             :integer(4)      
#  calendar             :boolean(1)      
#  message_id           :integer(4)      
#

class WorkSheetStateChange < Activity
  
  belongs_to :work_sheet, :foreign_key => 'message_id'
  
  def description
    if old_state == new_state # Hack to display new work sheet
      "nouveau bon <strong>" + I18n.t(new_state, :scope => :work_sheet) + "</strong>"
    else
      I18n.t(old_state, :scope => :work_sheet) + " -> <strong>" + I18n.t(new_state, :scope => :work_sheet) + "</strong>"
    end
  end
  
  def old_state
    body
  end
  def old_state=(state)
    write_attribute(:body, state)
  end
  
  def new_state
    title
  end
  def new_state=(state)
    write_attribute(:title, state)
  end
end
