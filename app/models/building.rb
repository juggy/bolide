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

class Building < Party
  
  define_index do
    indexes :name, :building_instruction, :internal_instructions
    indexes address.location, address.street, address.city, address.state, address.country, address.zip
    #TODO: cache in db
    indexes "CONCAT(tc_company_id,LPAD(icc_number,4, '0'))", :as => :icc_ref
    set_property :delta => true
    
    has :account_id
  end
  
  def self.find_duplicates( address )
    ThinkingSphinx.search( address.to_duplicate_sphinx_search_term, :match_mode => :extended2, :classes => [Building], :with => {:account_id => Account.current_account_id} )
  end
  
  has_one :address, :foreign_key => :party_id, :dependent => :destroy
  has_many :projects
  belongs_to :contract
  belongs_to :tc_company
  belongs_to :region
  belongs_to :building_type
  belongs_to :technology
  
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  validates_presence_of :address, :message => _("Vous devez entrer une adresse")
  validates_uniqueness_of :icc_number, :scope => :account_id, :allow_nil => false
  
  before_validation_on_create :assign_icc_number
  attr_protected :icc_number, :contract_type_id
  
  def merge!(*others)
    Merger::Merge.new(others, :keep => self, :fast => true).merge!
  end
  
  def display_name
    icc_ref ? "#{super} [#{icc_ref}]" : super
  end
  
  def quick_search_name
    address ? "#{display_name} - #{address.city}#{", #{address.location}" unless address.location.blank?}" : display_name
  end
  
  def icc_ref
    "#{tc_company_id}#{"%04d" % icc_number}" if !icc_number.blank? && tc_company_id
  end
  
  def full_instructions
    ins = []
    ins << "Note interne: #{internal_instructions}" unless internal_instructions.blank?
    ins << "Note pour bon de travail: #{building_instruction}" unless building_instruction.blank?
    ins.join("\r\n\r\n")
  end
  
  def last_foremen( max = 2 )
    values = self.connection.select_all("
      select p.id as project_id, ws.id as work_sheet_id, max(i.date) as date, i.foreman_id as user_id from parties b 
      inner join projects p on p.building_id = b.id 
      inner join work_sheets ws on ws.project_id = p.id 
      inner join interventions i on i.work_sheet_id = ws.id 
      where b.id = #{self.id}
      group by work_sheet_id, i.foreman_id 
      order by date 
      desc limit #{max}
    ")
    values.each do |val|
      val["user"] = User.find(val["user_id"])
    end
  end
  
  def contract?
    !!contract_id
  end
  
  def all_audits
    all = []
    all.concat audits
    all.concat address.audits
    all.reject {|a| a.changes.keys.size == 0}.sort_by(&:created_at).reverse
  end
  
  def after_initialize
    if self.new_record?
      self.address || build_address
    end
  end
  
  def address_attributes=(attrs)
    # after_initialize is not yet called if we build the address in Building.new
    self.address || build_address
    self.address.update_attributes attrs
  end
  
  def contract_attributes=(attrs)
    return if attrs.values.all? { |val| val.blank? }
    self.contract || build_contract
    self.contract_type_id = attrs[:contract_type_id] if attrs[:contract_type_id]
    self.contract.update_attributes attrs
  end
  
  def full_address
    self.address.to_s
  end
  
  protected
  def assign_icc_number
    self.icc_number ||= SystemSetting.next_building_icc_number
  end
  
end
