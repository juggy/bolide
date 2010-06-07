# == Schema Information
# Schema version: 20090401194129
#
# Table name: attachments
#
#  id              :integer(4)      not null, primary key
#  attachable_id   :integer(4)      
#  content_type    :string(255)     
#  filename        :string(255)     
#  size            :integer(4)      
#  attachable_type :string(255)     
#

# == Schema Information
# Schema version: 76
#
# Table name: attachments
#
#  id              :integer(11)     not null, primary key
#  attachable_id   :integer(11)     
#  content_type    :string(255)     
#  filename        :string(255)     
#  size            :integer(11)     
#  attachable_type :string(255)     
#
require 'unicode'
 
class Attachment < ScopedByAccount
  belongs_to :attachable, :polymorphic => true
  
  USE_FILE_SYSTEM = Rails.env.test? || Rails.env.production? # test and toiture couture for now
  
  if USE_FILE_SYSTEM
    has_attachment :storage => :file_system, :path_prefix => 'public/attachments', :max_size => 50.megabytes
  else
    has_attachment :storage => :s3, :max_size => 20.megabytes, :s3_access => :private
  end
  
  validates_as_attachment
  
  def self.normalize_filename(filename)
    Unicode.normalize_KD( filename.gsub( /\.attachment-blocked-or-renamed.*/i, "") ).gsub(/[^\x00-\x7F]/n,'')
  end
  
  if !USE_FILE_SYSTEM
    alias_method :unprotected_public_filename, :public_filename
    def public_filename
      authenticated_s3_url()
    end
  end
  
end
