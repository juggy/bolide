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

class Company < PartyWithManyContactMethods
  
  define_index do
    indexes :name
    indexes contact_data.value
    indexes addresses.location, addresses.street, addresses.city, addresses.state, addresses.country, addresses.zip
    set_property :delta => true
    has :account_id
  end
  
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  validates_uniqueness_of :name, :scope => :account_id, :message => _("Une compagnie existe déjà avec ce nom")
  
  has_many :courses
  
  belongs_to :manager,  :class_name => "User",    :foreign_key => :manager_id
  
  has_many :contracts, :foreign_key => :client_id
  
  has_many :projects, :foreign_key => "client_id" do
    def build(options = {})
      options.reverse_merge!( { :name => proxy_owner.name } )
      super(options)
    end
  end
  
  has_one :aged_account, :foreign_key => "client_id"
  def get_aged_account
    self.aged_account || self.build_aged_account
  end
  
  named_scope :for_manager, lambda {|user| user.blank? ? {} : {:conditions => ["manager_id = ?", user]} }
  
  def merge!(*others)
    Merger::Merge.new(others, :keep => self, :fast => true).merge!
  end
  
  def is_owner?
    self.id.to_s == SystemSetting.owner_id.to_s
  end
   
  def buildings
    self.relationships.active.find(:all, :include => [:third_party]).collect {|rel| rel.third_party if rel.third_party.is_a?(Building) }.compact
  end
  
  def has_buildings?
    Building.count('1', :joins => "inner join relationships r on parties.id = r.third_party_id and r.first_party_id = #{self.id} and deleted_at is null") > 0
  end
  
  def phone
    cphone = self.phone_numbers.first.value rescue nil
    cphone ||= self.company.phone_numbers.first.value rescue nil
    cphone
  end
  
  def full_instructions
    internal_instructions
  end
end
