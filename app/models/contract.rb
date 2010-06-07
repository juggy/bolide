# == Schema Information
# Schema version: 20090408154321
#
# Table name: contracts
#
#  id               :integer(4)      not null, primary key
#  number           :string(20)      
#  client_id        :integer(4)      
#  contract_type_id :integer(4)      
#  start_on         :date            
#  end_on           :date            
#  created_at       :datetime        
#  updated_at       :datetime        
#

class Contract < ScopedByAccount
  
  ### Associations
  
  belongs_to :client, :class_name => "Company", :foreign_key => "client_id"
  has_many :buildings, :order => 'name asc', :before_add => :building_has_no_other_contract, :after_remove => :building_removed
  has_many :projects
#  has_many :work_sheets
  belongs_to :contract_type
  
  
  ### Validations
  
  validates_presence_of :client_id, :contract_type_id
  #validates_presence_of :end_on, :message => N_("Date de fin requise")
  
  ### Callbacks
  
  def after_save
    ### Hack, currently the highest priotiry contarct type has a lower id, so thats what we'll use
    ctype = self.client.contracts.size > 1 ? self.client.contracts.collect(&:contract_type_id).min : self.contract_type_id
    self.client.update_attribute(:contract_type_id, ctype)
    self.buildings.each {|p| p.update_attribute(:contract_type_id, self.contract_type_id)}
  end
  
  
  def related_buildings
    client.relationships.collect {|r| r.third_party}.select {|p| p.is_a?(Building) } if client
  end
  ### 
  
  def name
    "#{contract_type} - #{client.quick_search_name}"
  end
  
  def short_name
    "#{client.quick_search_name}"
  end
  
  def display_name
    name
  end
  
  def secp?
    contract_type_id == ContractType::SECP_ID
  end

  def secpp?
    contract_type_id == ContractType::SECPP_ID
  end
  
  def is_priority?
    [ContractType::SECPP_ID, ContractType::SECP_ID].include?(contract_type_id)
  end
  
  def to_s
    name
  end
  
  protected
  def building_has_no_other_contract(building)
    raise "Building already has a contract" if building.contract? && building.contract != self
  end
  def building_removed(building)
    building.update_attribute(:contract_type_id, nil)
  end
end
