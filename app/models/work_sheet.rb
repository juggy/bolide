# == Schema Information
# Schema version: 20090408154321
#
# Table name: work_sheets
#
#  id                   :integer(4)      not null, primary key
#  project_id           :integer(4)      
#  contact_id           :integer(4)      
#  description          :text            
#  work_sheet_state_id  :integer(4)      
#  foreman_id           :integer(4)      
#  created_at           :datetime        
#  updated_at           :datetime        
#  result_description   :text            
#  state                :string(20)      
#  scheduled_date       :date            
#  work_date            :date            
#  scheduled_time       :float           
#  work_time            :float           
#  invoice_no           :string(20)      
#  invoice_date         :date            
#  invoice_amount       :decimal(10, 2)  default(0.0)
#  height               :integer(4)      
#  area                 :integer(4)      
#  work_type_id         :integer(4)      
#  technology_id        :integer(4)      
#  manager_id           :integer(4)      
#  project_manager_id   :integer(4)      
#  roofer_cost          :decimal(10, 2)  default(0.0)
#  materials_cost       :decimal(10, 2)  default(0.0)
#  machinery_cost       :decimal(10, 2)  default(0.0)
#  service              :boolean(1)      default(TRUE)
#  ideal_start_date     :date            
#  remaining_days       :float           
#  estimated_days       :float           
#  scheduled_end_date   :date            
#

require 'fastercsv'

class WorkSheet < ScopedByAccount
  
  # DEPARTMENTS = ['service', 'contract', 'tinman'].freeze
  # DEPARTMENTS.each do |dept|
  #   define_method("#{dept}?") do
  #     self.department == dept
  #   end
  # end
  
  acts_as_audited
  
  # attr_protected :remaining_days
  before_save :update_remaining_days
  
  # validates_numericality_of :profit_pct, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100
  
  belongs_to :project
  belongs_to :department
  
  #belongs_to :work_sheet_state
  belongs_to :foreman, :class_name => "User", :foreign_key => "foreman_id"
  belongs_to :manager,  :class_name => "User",    :foreign_key => :manager_id
  belongs_to :project_manager,  :class_name => "User",    :foreign_key => :project_manager_id
  
  belongs_to :contact, :class_name => "Party", :foreign_key => "contact_id"
  belongs_to :work_type
  belongs_to :technology
  
  has_many :state_changes, :class_name => "WorkSheetStateChange", :foreign_key => "message_id", :dependent => :destroy
  
  has_many :interventions, :order => 'date asc', :dependent => :destroy
  has_many :not_invoiced_interventions, :class_name => "Intervention",  :conditions => ["interventions.invoice_id IS NULL"]
  has_many :invoiced_interventions, :class_name => "Intervention",  :conditions => ["interventions.invoice_id IS NOT NULL"]
   
  has_many :invoices
  
  delegate :contract_number, :project_director, :building, :building_type, :tc_company, :priority?, :to => :project
  
  # named_scope :service, :conditions => {:department => 'service'}
  # named_scope :contract, :conditions => {:department => 'contract'}
  # named_scope :tinman, :conditions => {:department => 'tinman'}
  named_scope :for_department, lambda {|d| 
      d.blank? ? {} : {:conditions => {:department_id => d } }
    }
  
  named_scope :for_foreman, lambda {|user| user.blank? ? {} : {:conditions => ["foreman_id = ?", user]} }
  named_scope :with_foreman, lambda {|user|
      user = nil if user.blank? 
      {:conditions => {:foreman_id => user} } 
    }
  
  named_scope :for_manager, lambda {|user| user.blank? ? {} : {:conditions => ["manager_id = ?", user]} }
  named_scope :for_project_manager, lambda {|user| user.blank? ? {} : {:conditions => ["project_manager_id = ?", user]} }
  named_scope :with_project_manager, lambda {|user|
      user = nil if user.blank? 
      {:conditions => {:project_manager_id => user} } 
    }
  
  named_scope :for_state, lambda {|st| st.reject{|e| e.blank?}.blank? ? {} : {:conditions => ["work_sheets.state in (?)", st]} }
  named_scope :invoice_min_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:include => "invoices", :conditions => ["invoices.invoice_date >= ?", date] }
  }
  named_scope :invoice_max_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:include => "invoices", :conditions => ["invoices.invoice_date <= ?", date] }
  }
  
  named_scope :end_min_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["scheduled_end_date >= ?", date] }
  }
  named_scope :end_max_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["scheduled_end_date <= ?", date] }
  }
  
  named_scope :schedule_order, :order => "-scheduled_date DESC" #MYSQL hack to get nil at the end
  named_scope :to_show_in_schedule, :conditions => ["work_sheets.state in (?)", ['to_schedule', 'to_measure', 'preparation', 'to_install', 'finition']]
  
  def self.for_schedule(user_id = nil, department_id = nil, grouped_by = 'foreman_id')
    scope = WorkSheet.to_show_in_schedule
    if user_id == 'all'
      return scope.schedule_order
    elsif user_id.blank? 
      scope = scope.for_department(department_id).with_foreman(nil)
    elsif grouped_by == 'project_manager_id'
      scope = scope.with_project_manager(user_id)
    else
      scope = scope.with_foreman(user_id)
    end
    # elsif user_id == 'service'
    #   scope = scope.service
    #   user_id = nil
    # elsif user_id == 'contract'
    #   scope = scope.contract
    #   user_id = nil
    # elsif user_id == 'tinman'
    #   scope = scope.tinman
    #   user_id = nil
    # end
    
    
    scope.schedule_order
  end
  
  def self.auto_complete_search(query)
    no = query.downcase.strip
    self.scoped( :conditions => ["LOWER(projects.name) LIKE ? OR projects.call_number LIKE ? OR projects.quote_number LIKE ? OR projects.contract_number LIKE ? OR projects.po_number LIKE ? OR work_sheets.id LIKE ?", "%#{no}%", "#{no}%","#{no}%","#{no}%","#{no}%", "%#{no}%"], :include => 'project', :limit => 10)
  end
  
  ### Planning
  class PlannedIntervention
    attr_reader :work_sheet, :day, :remaining
    def initialize(work_sheet, day, remaining, time = 1.0, type = 'work_sheet')
      @work_sheet = work_sheet
      @day = day
      @remaining = remaining
      @type = type
      @time = time || 1.0
    end
    
    def rtime
      @time
    end
    def time
      @time if @time < 1.0
    end
    
    def intervention?
      @type == 'intervention'
    end
  end
  
  def planned_interventions
    @planned_interventions ||= 
      if scheduled_date && remaining_days <= 0
        []
      else
        planning = []
        current_day = [DailySchedule.next_day_to_schedule, scheduled_date].compact.max
        r_days = remaining_days || 0.0
      
        while (r_days > 0 ) do
          if CompanyCalendar.works_on?(current_day) || current_day == scheduled_date
          
            week_factor = CompanyCalendar.planned_day_weight_on(current_day, department)
            r_days -= week_factor
            planning << PlannedIntervention.new(self, current_day, r_days, [week_factor, r_days].min)
          
          end
          current_day += 1.day
        end
      
        planning
      end
  end
  
  def planned_end_date
    if last_planned = planned_interventions.last
      last_planned.day
    elsif last_intervention_date
      last_intervention_date
    else
      scheduled_date
    end
  end
  
  def last_intervention_date
    if self.interventions.size > 0
      interventions.last.date
    end
  end
  
  ### Callbacks
  
  def after_initialize
    @previous_state = self.state
    if new_record?
      self.state ||= 'new'
    end
    # if execution?
    #   self.foreman ||= self.scheduled_foreman
    #   self.work_date ||= self.scheduled_date
    #   self.work_time ||= self.scheduled_time
    # end
  end
  
  def after_save
    # if @previous_state.to_s != self.state.to_s
    if self.state_changed?
      self.state_changes.create!(:old_state => @previous_state, :new_state => self.state,
                        :user_id => User.current_user.id, :project_id => self.project.id)
                        
      @previous_state = self.state.to_s
    end
  end
  
  def use_project_defaults
    if self.project
      self.foreman ||= project.foreman
      self.description ||= project.building.building_instruction if project && project.building
      self.area ||= project.area
      self.height ||= project.height
      self.work_type ||= project.work_type
      self.technology ||= project.technology
      self.manager ||= project.manager
      self.project_manager ||= project.project_manager
      self.scheduled_time ||= project.quoted_roofer_time
      self.department_id ||= project.department_id
    end
  end
  
  def duplicate
    self.project.work_sheets.build(
        self.attributes.except("id", "created_at", "updated_at", "state", "result_description", "invoice_no", "invoice_date", "invoice_amount", "roofer_cost", "materials_cost", "machinery_cost")
    )
  end
  
  ####
  
  def default_display_name(department)
    if department != self.department
      self.display_name
    else
      project.display_name
    end
  end
  
  def display_name
    # TODO: Temporary visual cue
    prefix = "[#{self.department}]"
    "#{prefix} #{project.display_name}" #"#{id} - #{call_number} - #{project.display_name}"
  end
  
  def contract_display_name
    # TODO: Temporary visual cue
    prefix = "[#{self.department}]"
    "#{prefix} - #{project.contract_number} - #{project.display_name} (#{project.state_name})"
  end
  
  def full_display_name
    # TODO: Temporary visual cue
    prefix = "[#{self.department}]"
    "#{prefix} - P:#{project.contract_number} - A:#{project.call_number} - ##{self.id} - #{project.display_name}" #"#{id} - #{call_number} - #{project.display_name}"
  end
  
  
  def contact_on_site
    if self.contact
      carr = [self.contact.quick_search_name]
      if self.contact.phone_numbers.size > 1
        self.contact.phone_numbers.each do |pn|
          carr << "#{pn.name}: #{pn.value}"
        end
      else
        carr << "Tel: #{self.contact_phone}"
      end
      carr.join("\n")
    else
      self.project.call.contact_on_site rescue ""
    end
  end
  
  def contact_couture(intervention = nil)
    lines = []
    lines << "Gestionnaire de compte: #{self.manager.full_name}" if self.manager
    lines << "Tel: #{self.manager_phone}" if self.manager
    lines << "Chargé de projet: #{self.project_manager.full_name}" if self.project_manager
    lines << "Tel: #{self.project_manager_phone}" if self.project_manager
    lines << "Chef d'équipe: #{intervention.foreman.full_name}" if intervention && intervention.foreman
    lines.join("\n")
  end
  
  def manager_phone
    nums = self.manager.contact.phone_numbers
    num = nums.detect { |n| n.name =~ /cell/ }
    num ? num.value : nums.first.value 
  rescue 
    nil
  end
  
  def project_manager_phone
    nums = self.project_manager.contact.phone_numbers
    num = nums.detect { |n| n.name =~ /cell/ }
    num ? num.value : nums.first.value 
  rescue 
    nil
  end
  
  def contact_phone
    cphone = self.contact.phone_numbers.first.value rescue nil
    cphone ||= self.contact.company.phone_numbers.first.value rescue nil
    cphone
  end

  def call_number
    project.call_number
  end
  
  def has_intervention?
    interventions.length > 0
  end
  
  def destroyable?
    !has_intervention?
  end
  
  ### State mgmt
  
  SERVICE_STATES = ['new', 'to_schedule', 'finition', 'acceptation', 'to_invoice', 'invoiced']
  CONTRACT_STATES = ['to_schedule', 'finition', 'acceptation', 'finished']
  TINMAN_STATES = ['waiting', 'to_measure', 'preparation', 'to_install', 'finition', 'acceptation', 'finished']
  
  ALL_STATES = (SERVICE_STATES + CONTRACT_STATES + TINMAN_STATES).uniq
  
  STATES = ['waiting', 'to_schedule', 'acceptation', 'to_invoice', 'invoiced', 'finished']
  # STATE_NAMES = {
  #     'new' => N_("en préparation"),
  #     'to_schedule' => N_("à céduler"),
  #     'acceptation' => N_("acceptation"),
  #     'to_invoice' => N_("à facturer"),
  #     'invoiced' => N_("facturé")
  #   }
  validates_inclusion_of :state, :in => ALL_STATES
  ALL_STATES.reject {|st| st == 'new'}.each do |st|
    named_scope st.to_sym, :conditions => ['work_sheets.state = ?',st]
    define_method("#{st}?") do
      self.state == st
    end
  end
  
  def department_name
    department.to_s
  end
  
  def state_name
    #STATE_NAMES[state]
    I18n.t(state, :scope => :work_sheet)
  end
  
  def self.department_select_options
    # DEPARTMENTS.map {|d| [ I18n.t(d, :scope => :work_sheet), d ]}
    Department.all.map {|d| [d.to_s, d.id]}
  end
  
  def self.all_state_select_options
    (Account.current_account.tc? ? ALL_STATES : STATES).
        map {|s| [ I18n.t(s, :scope => :work_sheet), s ]}
  end
  
  def self.state_select_options( dept = 'service')
    # const_get("#{dept}_states".upcase).map {|s| [ I18n.t(s, :scope => :work_sheet), s.to_s] }
    #ALL_STATES.map {|s| [ I18n.t(s, :scope => :work_sheet), s.to_s] }
    self.all_state_select_options
  end
  
  def done!
    update_attributes(:state => 'to_invoice')
  end
  
  def invoice!(params)
    invoice_data_complete = params.except("project_manager_id","invoice_no").values.all? {|v| !v.blank?} #&& params[:invoice_amount].to_f != 0.0
    params.merge!(:state => 'invoiced') if invoice_data_complete
    update_attributes(params)
    invoice_data_complete
  end
  
  def completed?
    ['acceptation', 'to_invoice', 'invoiced'].include? self.state
  end
  
  def complete!
    update_attribute(:state, 'acceptation') unless self.invoiced? || self.to_invoice?
  end
  
  ### Reporting
  
  def self.report_csv(work_sheets, separator = ",")
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      csv <<   ["No Appel", 
                "No projet", 
                "Immeuble", 
                "Gestionaire", 
                "Chef d'équipe", #5
                "Date Facture",
                "# Facture",
                "Hres réelles",
                "Cout M.O.",
                "Cout Materiaux",
                "Cout Equipement",
                "Montant facturé",
                "Profit",
                "% profit"
              ]
              
      work_sheets.each do |ws|
        csv << [ws.call_number, 
                ws.contract_number,
                ws.building.name,
                ws.manager_name,
                ws.foreman_name, #5
                ws.invoice_date, #.localize(:short),
                ws.invoice_no,
                ws.real_time,
                ws.roofer_cost,
                ws.materials_cost,
                ws.machinery_cost,
                ws.invoice_amount,
                ws.profit,
                ws.profit_pct
              ]
      end
      
    end
  end
  
  def manager_name
    manager ? manager.full_name : ""
  end
  
  def foreman_name
    foreman ? foreman.full_name : ""
  end
  
  def work_end_date
    self.interventions.last.date rescue nil
  end
  
  def real_time
    self.interventions.inject(0.0) do |sum,i|
      sum += (i.work_time || 0.0)
    end
  end
  
  def total_cost
    self.invoices.inject(0.0) do |sum,i|
      sum += (i.total_cost || 0.0)
    end
  end
  
  def profit
    self.invoices.inject(0.0) do |sum,i|
      sum += (i.profit || 0.0)
    end
  end
  
  def total_invoice_amount
    self.invoices.inject(0.0) do |sum,i|
      sum += (i.invoice_amount || 0.0)
    end
  end
  
  def profit_pct
    (profit / total_invoice_amount).to_f * 100.0
  end
  
  
  def po_date
    self.project.won_date.to_date.localize(:default) if self.project.won_date
  end
  
  def client_name
    self.project.client.name if self.project.client
  end
  
  def documenter_name
    self.project.documenter.full_name if self.project.documenter
  end
  
  
  def update_done_days!
    self.done_days = Intervention.sum(:work_days, :conditions => {:work_sheet_id => self.id})
    self.save
  end
  
  def real_days
    (estimated_days || 0.0) + (extra_days || 0.0)
  end
  
  protected
  
  def update_remaining_days
    self.remaining_days = real_days - (done_days || 0.0)
  end
end
