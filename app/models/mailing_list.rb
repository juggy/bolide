# == Schema Information
# Schema version: 20090408154321
#
# Table name: mailing_lists
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     
#  recipients :text            
#  user_id    :integer(4)      
#  private    :boolean(1)      
#  created_at :datetime        
#  updated_at :datetime        
#

class MailingList < ScopedByAccount
  
  validates_presence_of :name
  validates_presence_of :recipients
  
  belongs_to :user
  
  def recipients_count
    recipients.split(",").size
  end
  before_create do |record| 
    record.user = User.current_user
  end
  
end
