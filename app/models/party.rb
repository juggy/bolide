# == Schema Information
# Schema version: 20090408154321
#
# Table name: parties
#
#  id                    :integer(4)      not null, primary key
#  type                  :string(255)     
#  first_name            :string(255)     
#  last_name             :string(255)     
#  title                 :string(255)     
#  name                  :string(255)     
#  created_at            :datetime        
#  updated_at            :datetime        
#  user_id               :integer(4)      
#  manager_id            :integer(4)      
#  contract_type_id      :integer(4)      
#  building_instruction  :text            
#  contract_id           :integer(4)      
#  icc_number            :integer(4)      
#  tc_company_id         :integer(4)      
#  internal_instructions :text            
#  region_id             :integer(4)      
#  building_type_id      :integer(4)      
#  technology_id         :integer(4)      
#  height                :integer(4)      
#

# require 'gettext/rails'

class Party < ScopedByAccount
  extend StripAttributes
  strip_attributes! :only => [:first_name, :last_name, :name, :title]
  
  def to_s; name; end

  acts_as_audited
  acts_as_taggable
  
  def all_audits
    audits
  end
  
  def self.search(term, options = {})
    ThinkingSphinx.search(term, options.merge(:classes => [Building, Contact, Company], :with => {:account_id => Account.current_account_id})) 
  end
  
  named_scope :last_created, :limit => 20, :order => 'created_at desc'
  has_many :relationships, :foreign_key => 'first_party_id'
  has_many :third_parties, :through => :relationships, :foreign_key => 'third_party_id'
  
  # both below used only for correct merge of relations, not needed in general use of the app
  has_many :inverse_relationships, :foreign_key => 'third_party_id', :class_name => 'Relationship'
  has_many :first_parties, :through => :inverse_relationships, :foreign_key => 'first_party_id'
  
  has_many :involvements, :dependent => :destroy
  has_many :related_projects, :through => :involvements, :class_name => 'Project', :foreign_key => 'project_id', :source => 'project'
  
  has_many :message_recipients, :dependent => :nullify
    
  has_many :activities, :dependent => :destroy
  has_many :tasks, :dependent => :destroy
  has_many :notes, :dependent => :destroy
  has_many :linked_messages, :dependent => :destroy
  has_many :file_attachments, :dependent => :destroy
  
  belongs_to :contract_type
  
  def display_name
    name
  end
  
  def quick_search_name
    display_name
  end
  
  def self.find_by_email(email = "")
    # Party.find(:all, :joins => "LEFT JOIN contact_data ON (contact_data.party_id = parties.id)", :conditions => ["contact_data.type = 'Email' and contact_data.value = ?", email])
    Party.find( Email.find(:all, :conditions => {:value => email}).collect(&:party_id) )
  end
  
  def destroy
    Party.transaction do
      relations.each {|r| r.force_destroy }
      self.involvements.each {|inv| inv.force_destroy }
      super
    end
  end
  
  def relations
    self.relationships.collect {|r| Relation.find(r) }
  end
  
  def self.auto_complete_search(term)
    search_string = "%#{term.downcase.strip}%"
    #name_search_string = "%#{term.downcase.strip.split('').join('%')}%"
    find(:all, 
      :conditions => ["LOWER(name) LIKE ? or CONCAT(tc_company_id,LPAD(icc_number,4, '0'))  like ?", search_string, search_string],
            :order => "name, last_name, first_name",
            :limit => 10)
  end
end
