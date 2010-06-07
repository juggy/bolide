# == Schema Information
# Schema version: 20090408154321
#
# Table name: contact_data
#
#  id       :integer(4)      not null, primary key
#  party_id :integer(4)      
#  type     :string(255)     
#  name     :string(255)     
#  value    :string(255)     
#

# require 'gettext/rails'

class ContactDatum < ScopedByAccount
  set_table_name 'contact_data'
  strip_attributes! :only => [:name,:value]
  
  acts_as_audited
  belongs_to :party
  
end
