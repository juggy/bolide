# == Schema Information
# Schema version: 20090408154321
#
# Table name: invoices
#
#  id             :integer(4)      not null, primary key
#  invoice_no     :string(20)      
#  invoice_date   :date            
#  invoice_amount :decimal(10, 2)  default(0.0)
#  roofer_cost    :decimal(10, 2)  default(0.0)
#  materials_cost :decimal(10, 2)  default(0.0)
#  machinery_cost :decimal(10, 2)  default(0.0)
#  user_id        :integer(4)      
#  work_sheet_id  :integer(4)      
#  state          :string(20)      
#  created_at     :datetime        
#  updated_at     :datetime        
#

class Invoice < ScopedByAccount
  belongs_to :creator,  :class_name => "User",    :foreign_key => :user_id
  belongs_to :work_sheet
  has_many :interventions, :dependent => :nullify
  
  validates_presence_of :user_id, :work_sheet_id, :invoice_no, :invoice_date, :invoice_amount
  #validates_uniqueness_of :invoice_no, :scope => :account_id
  validates_numericality_of :invoice_amount, :roofer_cost, :materials_cost, :machinery_cost
  
  #validate :number_of_interventions
  
  delegate :contract_number, :call_number, :project, 
            :manager, :project_manager, :project_director, :foreman, :technology, :work_type, :building_type, :source,
            :manager_name, :foreman_name, 
            :to => :work_sheet
  
  named_scope :for_invoice_type, lambda { |t| t == 'all' ? {} : {:conditions => {:invoice_type => t } } }
  named_scope :min_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["invoice_date >= ?", date] }
  }
  named_scope :max_date, lambda { |d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["invoice_date <= ?", date] }
  }
  
  
  before_save :cache_invoice_type
  after_save :mark_work_sheet_as_invoiced
  
  def attached_interventions=intervention
    intervention.each { |id, val|

      i = Intervention.find(id)
      
      if val.delete("checked") == "checked"
        i.update_attributes(val)
        self.interventions << i unless self.interventions.include?(i)
      else
        if self.interventions.length == 1
          errors.add_to_base "Vous devez associer au moins 1 intervention"
        else
          self.interventions.delete i
        end
      end
    }
  end
  
  def real_time
    self.interventions.inject(0.0) do |sum,i|
      sum += (i.work_time || 0.0)
    end
  end
  
  def invoice_type_name
    self.interventions[0] ? self.interventions[0].invoice_type_name : Intervention::INVOICE_TYPE_NAMES['']
  end
  
  def total_cost
    [ self.roofer_cost,
      self.materials_cost,
      self.machinery_cost
    ].sum
  end
  
  def profit
    invoice_amount - total_cost
  end
  
  def profit_pct
    (profit / invoice_amount).to_f * 100.0
  end
  
  def work_end_date
    self.interventions.last.date rescue nil
  end
  
  # CSV
  def self.report_service_invoices_csv(data, separator = ",")
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      csv <<   ["No projet", 
                "Projet", 
                "Estimateur",
                "Gestionnaire de compte",
                "Chargé de projet",
                "Chef d'équipe",
                "Fin des travaux",
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

      data.each do |d|
        csv << [d.project.contract_number, 
                d.project.name,
                d.project.estimator,
                d.manager_name,
                d.project.project_manager,
                d.foreman_name,
                d.work_end_date,
                d.invoice_date,
                d.invoice_no,
                d.real_time,
                d.roofer_cost,
                d.materials_cost,
                d.machinery_cost,
                d.invoice_amount,
                d.profit,
                d.profit_pct
              ]
      end
    end
  end
  
  private
  
  def cache_invoice_type
    self.invoice_type ||= self.interventions[0].invoice_type if self.interventions[0]
    true
  end
  
  def mark_work_sheet_as_invoiced
    if self.work_sheet.to_invoice? && self.work_sheet.not_invoiced_interventions.count == 0
      self.work_sheet.state = "invoiced"
      self.work_sheet.save
    end
  end
  
  def number_of_interventions
    errors.add_to_base "Vous devez associer au moins 1 intervention" if interventions.length == 0
  end
  
end
