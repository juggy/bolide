# == Schema Information
# Schema version: 20090408154321
#
# Table name: original_messages
#
#  id                 :integer(4)      not null, primary key
#  message_id         :integer(4)      
#  rfc2822_message_id :string(255)     
#  date               :datetime        
#  body               :binary          
#  created_at         :datetime        
#  updated_at         :datetime        
#

class OriginalMessage < ScopedByAccount
end
