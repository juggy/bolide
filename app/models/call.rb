# == Schema Information
# Schema version: 20090408154321
#
# Table name: calls
#
#  id              :integer(4)      not null, primary key
#  phone_number    :string(255)     
#  contact_id      :integer(4)      
#  description     :text            
#  project_id      :integer(4)      
#  activity_id     :integer(4)      
#  created_by_id   :integer(4)      
#  company_name    :string(255)     
#  contact_name    :string(255)     
#  address         :string(255)     
#  client_id       :integer(4)      
#  building_id     :integer(4)      
#  source_id       :integer(4)      
#  comm_source_id  :integer(4)      
#  call_type_id    :integer(4)      
#  reference       :string(255)     
#  reference_id    :integer(4)      
#  contact_on_site :text            
#  work_type_id    :integer(4)      
#

class Call < ScopedByAccount
  belongs_to :contact
  belongs_to :building
  belongs_to :client, :class_name => 'Company', :foreign_key => 'client_id'
  
  belongs_to :project
  belongs_to :activity
  created_by_user
  
  belongs_to :source, :class_name => "CallSource"
  belongs_to :comm_source, :class_name => "CallCommSource"
  belongs_to :call_type
  belongs_to :work_type
  belongs_to :call_reference, :foreign_key => "reference_id"
  
  define_index do
    indexes contact_name
    indexes company_name
    indexes phone_number
    indexes address
    set_property :delta => true
    has :account_id
  end
  # TODO
  # Temporary while the system does not auto assign
  #attr_accessor :call_number
  attr_accessor :area, :height, :ladder
  
  def after_create    
    client_options = {}
    if self.client
      client_options[:client] = self.client
      client_options[:estimator_id] = self.client.manager_id
      client_options[:manager_id] = self.client.manager_id
    end
    
    self.project = Project.create(
        {:state => "new_call", 
          :building => self.building, 
          :source_id => self.source_id, 
          :call_number => SystemSetting.next_call_number,
          :work_type => self.work_type,
          :area => @area, 
          :height => @height,
          :ladder => @ladder
          }.merge(client_options) )
    
    if self.contact
      self.project.involvements.create(:party => self.contact, :role => _("Contact principal"))
      #self.activity = self.contact.notes.create(:body => "APPEL: #{self.description}")
    end
    self.save
  end
  
  
  def display_source
    ([] << (comm_source.name if comm_source) << (source.name if source)).compact.join(' / ')
  end
  
  # To allow search
  def search_summary
    lines = []
    lines << self.contact_name unless self.contact_name.blank?
    lines << self.company_name unless self.company_name.blank?
    lines << self.phone_number unless self.phone_number.blank?
    lines << self.address unless self.address.blank?
    lines.join("\n")
  end
  
end
