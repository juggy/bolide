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

class FileAttachment < Activity

  define_index do
    indexes body
    # set_property :delta => true
    has :account_id
  end
  
  has_many :attachments, :as => :attachable, :dependent => :destroy
  
  def attachment
    attachments.first
  end
  
  def uploaded_data=(data)
    self.attachments.build(:uploaded_data => data)
  end
  
end
