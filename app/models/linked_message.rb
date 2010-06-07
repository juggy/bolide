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

class LinkedMessage < Activity
  define_index do
    indexes message.subject, message.body
    has :account_id
  end
  belongs_to :message, :counter_cache => :linked_messages_count
  
  delegate :body, :text_body, :to => :message
  
  validates_presence_of :message_id
  validate :linked_to_party_or_project
  
  def subject
    self.title.present? ? self.title : message.subject
  end
  
  def linked_to
    self.project or self.party
  end
  
  def linked_to_party_or_project
    self.project_id = nil if self.project_id == 0 #IE bug with autocomplete
    self.party_id = nil if self.party_id == 0
    if self.project_id.nil? && self.party_id.nil?
      errors.add_to_base("Doit être lié à un contact ou à un projet")
    end
  end
  
  def before_save
    self.private = self.message.private
    self.created_at = self.message.created_at
    self.updated_at = self.message.created_at
    true # if false, save would abort
  end
  
  def received?
    message.received?
  end
  

  def save_with_notimestamps(*args)
    begin
      self.class.record_timestamps = false
      save_without_notimestamps(*args) # double negation are fun
    ensure
      self.class.record_timestamps = true
    end
  end
  alias_method_chain :save, :notimestamps
  
end
