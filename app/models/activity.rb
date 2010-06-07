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

class Activity < ScopedByAccount
  
  belongs_to :user
  belongs_to :party
  belongs_to :project
  
  belongs_to :activity_category
  
  named_scope :history, :conditions => ["((type = 'Task' AND closed_at is NOT NULL) OR (type <> 'Task')) AND (private = ? OR ( private = ? and user_id = ? ) )", false, true, User.current_user], :order => 'updated_at desc'
  
  named_scope :by_type, lambda {|activity_type| activity_type.blank? ? {} : {:conditions => ["type = ?",activity_type] }}
  named_scope :by_user, lambda {|user_id| user_id.blank? ? {} : {:conditions => ["user_id = ?", user_id] } }
  named_scope :by_category, lambda {|category_id| category_id.blank? ? {} : {:conditions => ["activity_category_id = ?", category_id] } }
  
  def category
    activity_category
  end
  
  def category=(cat)
    activity_category=cat
  end
  
end
