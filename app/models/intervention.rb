# == Schema Information
# Schema version: 20090408154321
#
# Table name: interventions
#
#  id                            :integer(4)      not null, primary key
#  work_sheet_id                 :integer(4)      
#  foreman_id                    :integer(4)      
#  date                          :date            
#  scheduled_time                :float           
#  result_description            :text            
#  completed                     :boolean(1)      
#  work_time                     :float           
#  invoice_no                    :string(255)     
#  invoice_date                  :date            
#  invoice_amount                :decimal(10, 2)  default(0.0)
#  roofer_cost                   :decimal(10, 2)  default(0.0)
#  materials_cost                :decimal(10, 2)  default(0.0)
#  machinery_cost                :decimal(10, 2)  default(0.0)
#  invoiced_with_intervention_id :integer(4)      
#  invoice_id                    :integer(4)      
#  invoice_type                  :string(255)     
#  invoice_comment               :string(255)     
#

class Intervention < ScopedByAccount
  belongs_to :work_sheet
  belongs_to :invoice
  belongs_to :foreman, :class_name => "User", :foreign_key => "foreman_id"
  belongs_to :schedule, :class_name => "DailySchedule", :primary_key => :date, :foreign_key => :date
  
  has_many :roofer_assignments, :class_name => "InterventionRoofer", :foreign_key => "intervention_id", :dependent => :destroy
  has_many :roofers, :through => :roofer_assignments
  
  validates_presence_of :work_sheet_id, :foreman_id, :date
  validates_uniqueness_of :work_sheet_id, :scope => [:account_id, :foreman_id, :date]
  
  delegate :project_manager, :contract_number, :building, :building_type, :technology, :to => :work_sheet
  
  default_value_for :work_days, 1.0
  
  named_scope :for_foreman, lambda {|user| user.blank? ? {} : {:conditions => ["foreman_id = ?", user]} }
  named_scope :non_completed_only, lambda{|bool| bool == "1" ? {:conditions => {:completed => false}} : {} }
  named_scope :min_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["date >= ?", date] }
  }
  named_scope :max_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["date <= ?", date] }
  }
  
  # def schedule
  #   @_schedule ||= DailySchedule.find_by_date(self.date) if self.date
  # end
  
  def assign_team
    Intervention.transaction do
      self.roofer_assignments.clear
      self.roofers << foreman
      foreman.team_members.each do |tm|
        self.roofers << tm unless self.roofers.include?(tm)
      end
    end
  end
  
  def date_fr
    date
  end
  
  def date_fr=(time)
    write_attribute(:date, fr_time( time ) )
  end
  
  attr_accessor :work_sheet_completed
  def work_sheet_completed
    self.work_sheet.completed? || @work_sheet_completed
  end
  
  def before_save
    if @work_sheet_completed == "1"
      self.work_sheet.complete!
    end
  end
  
  def after_save
    if (work_time_changed? || work_days_changed?) && schedule
      schedule.update_caches
    end
    work_sheet.update_done_days!
  end
  
  def after_destroy
    schedule.update_caches if schedule
    work_sheet.update_done_days!
  end
  
  def after_create
    self.work_sheet.done! if self.work_sheet && self.work_sheet.invoiced?
  end
  
  ### Invoice types
  INVOICE_TYPES = ['', 'sav service', 'sav contrat', 'error', 'contract']
  DEFAULT_INVOICE_TYPE = 'sav'
  INVOICE_TYPE_NAMES = {
      '' => N_("Normal"),
      'sav service' => N_("S.A.V. service"),
      'sav contrat' => N_("S.A.V. contrat"),
      'error' => N_("Erreur"),
      'contract' => N_("Contrat")
    }
  INVOICE_TYPES[1..-1].each do |st|
    named_scope st.to_sym, :conditions => ['interventions.invoice_type = ?',st]
    define_method("#{st}?") do
      self.invoice_type == st
    end
  end
  
  def invoice_type_name
    INVOICE_TYPE_NAMES[invoice_type] || INVOICE_TYPE_NAMES['']
  end
  
  def self.invoice_type_select_options
    INVOICE_TYPES.map {|s| [INVOICE_TYPE_NAMES[s], s.to_s] }
  end
end
