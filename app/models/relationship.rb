# == Schema Information
# Schema version: 20090408154321
#
# Table name: relationships
#
#  id             :integer(4)      not null, primary key
#  description    :string(255)     
#  first_party_id :integer(4)      
#  third_party_id :integer(4)      
#  created_at     :datetime        
#  deleted_at     :datetime        
#  tag            :string(255)     
#  principal      :boolean(1)      
#

class Relationship < ScopedByAccount
  
  # Relationships should read:
  # 'first_party' is 'description' of 'third_party'
  # ex: contact is employee of company
  
  
  belongs_to :first_party, :class_name => "Party", :foreign_key => 'first_party_id'
  belongs_to :third_party, :class_name => "Party", :foreign_key => 'third_party_id'
  
  validates_presence_of :description, :message => _("Vous devez entrer une description")
  validates_presence_of :first_party
  validates_presence_of :third_party
  
  # Finders
  named_scope :principal, :conditions => ["deleted_at is null AND principal = ?", true], :order => 'description'
  named_scope :secondary, :conditions => ["deleted_at is null AND principal = ?", false], :order => 'description'
  
  named_scope :active, :conditions => ["deleted_at is null"], :order => 'description'
  named_scope :inactive, :conditions => ["deleted_at is not null"], :order => 'deleted_at desc'
  
  named_scope :employee, :conditions => ["tag = 'employee'"]
  named_scope :employer, :conditions => ["tag = 'employer'"]
  
  # Relationship should never be destroyed by default, as we want to keep their history
  alias_method :force_destroy, :destroy
  def destroy(t = Time.now)
    self.update_attribute(:deleted_at, t)
  end
  
  def active?
    self.deleted_at.nil?
  end
  
  
  def self.suggestions(party, party_number, options = {})
    options.reverse_merge!({:limit => 10})
    
    result = self.connection.execute(
      "SELECT count(1) as desc_count, description 
      FROM relationships r 
      WHERE tag IS NULL 
        AND account_id = #{Account.current_account_id}
        AND #{party_number.to_s}_id IN 
        (select id from parties where type='#{party.class.to_s}') 
      GROUP BY description
      ORDER BY desc_count desc
      LIMIT #{options[:limit]}").all_hashes
    result.map {|d| d["description"]}
  end
end
