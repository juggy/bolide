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
require 'fastercsv'

class Contact < PartyWithManyContactMethods
  
  define_index do
    indexes :name
    indexes contact_data.value
    indexes addresses.location, addresses.street, addresses.city, addresses.state, addresses.country, addresses.zip
    set_property :delta => true
    has :account_id
  end
  
  validates_presence_of :first_name, :last_name, :message => _("Vous devez entrer un nom complet")
  
  has_many :projects, :foreign_key => 'client_id'
  belongs_to :user
  
  has_many :work_sheets, :dependent => :nullify
  has_many :calls, :dependent => :nullify
  
  # Human Resource (only on employee)
  has_many :competences, :foreign_key => 'employee_id', :order => 'expires_on ASC'
  has_one :employee_info
  has_many :absences, :foreign_key => 'employee_id', :order => 'start_date DESC'
  
  def merge!(*others)
    Merger::Merge.new(others, :keep => self, :fast => true).merge!
  end
  
  def after_initialize
    # if self.is_employee?
    #   self.employee_info || build_employee_info
    # end
  end
  
  def get_employee_info
    self.employee_info || build_employee_info
  end
  
  attr_accessor :company_name, :attach_to_message
  
  def quick_search_name
    company_name ? "#{name} - #{company_name}" : name
  end
  
  def company
    @company ||= begin
      first_rel = company_relationship
      first_rel.third_party if first_rel
    end
  end
  
  def is_employee?
    company ? company.is_owner? : false
  end
  
  def company_relationship
    relationships.active.employee.first
  end
  
  def company_name
    @company_name ||= (company.name if company)
  end
  
  def company_name=(name)
    return if name.blank?
    @company_name = name
    @new_company = Company.find_or_create_by_name(name)
  end
  
  def before_save
    write_attribute(:name, self.name)
  end
  
  def full_name
    "#{last_name} #{first_name}"
  end
  
  def after_save
    if @new_company != company
      if company
        Relation.find(company_relationship).destroy
      end
      Relation.create( {self => Relation::EMPLOYEE, @new_company => Relation::EMPLOYER}, {:principal => true} ) if @new_company
    end
  end
  
  def after_create
    if @attach_to_message
      self.linked_messages.create(:message_id => @attach_to_message)
    end
  end
  
  def primary_address
    self.addresses.first || (self.company.addresses.first if self.company)
  end
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def set_name=(str)
    self.first_name, self.last_name = str.split(" ", 2) if str
  end
  
  def reload_with_company
    @company = @new_company = nil
    reload_without_company
  end
  alias_method_chain :reload, :company
  
  def destroy
    raise "Cannot delete contact" if self.projects.count > 0
    super
  end
  
  public
    
    def self.phone_book_csv(contacts, separator = ',')
      phone_headers = contacts.inject([]) {| arr, c | arr << c.phone_numbers.collect {|num| (num.name || "").downcase}; arr  }.flatten.uniq.sort_by(&:to_s)
      FasterCSV.generate(:col_sep => separator) do |csv|
        # header row
        csv <<  (['nom', 'compagnie', 'adresse', "adresse", "pays"].concat phone_headers )
        
        # data rows
        contacts.each do |c|
          row = [c.full_name, c.company_name]
          
          if addr = c.primary_address
            row << addr.line1
            row << addr.line2
            row << addr.country
          else
            row << ""
            row << ""
            row << ""
          end
          
          phone_headers.each do |phone_name|
            named_phone = c.phone_numbers.detect {|num| (num.name || "").downcase == phone_name}
            row << (named_phone ? named_phone.value : nil)
          end
          
          csv << row
        end
      end
    end
    
end
