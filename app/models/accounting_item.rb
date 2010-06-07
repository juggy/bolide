# == Schema Information
# Schema version: 20090408154321
#
# Table name: accounting_items
#
#  id                         :integer(4)      not null, primary key
#  financial_year             :string(255)     
#  project_id                 :integer(4)      
#  invoiced_amount            :decimal(10, 2)  default(0.0)
#  created_at                 :datetime        
#  updated_at                 :datetime        
#  initial_contract_amount    :decimal(10, 2)  default(0.0)
#  with_extra_contract_amount :decimal(10, 2)  default(0.0)
#  estimated_initial_costs    :decimal(10, 2)  default(0.0)
#  as_of_today_costs          :decimal(10, 2)  default(0.0)
#  inventory_amount           :decimal(10, 2)  default(0.0)
#  to_be_completed_costs      :decimal(10, 2)  default(0.0)
#

class AccountingItem < ScopedByAccount 
  
  belongs_to :project
  
  validates_presence_of :project_id
  validates_uniqueness_of :financial_year, :scope => [:account_id, :project_id]
  validate :has_costs_validation
  validates_numericality_of :invoiced_amount, :initial_contract_amount, :with_extra_contract_amount, :estimated_initial_costs, :as_of_today_costs, :inventory_amount, :to_be_completed_costs
  
  named_scope :for_year, lambda {|financial_year| financial_year.blank? ? {:conditions => ["financial_year = ?", Time.now.strftime("%Y")]} : {:conditions => ["financial_year = ?", financial_year]} }
  
  named_scope :for_user, lambda {|user_id| {:conditions => ["projects.manager_id = ? OR projects.estimator_id = ? OR projects.foreman_id = ? OR projects.manager_id = ?", user_id, user_id, user_id, user_id], :include => :project } }
  
  # calculated fields
  def total_cost
    as_of_today_costs + inventory_amount + to_be_completed_costs
  end
  
  def real_invoicing
    ( as_of_today_costs * with_extra_contract_amount ) / total_cost
  end
  
  def invoice_difference
    invoiced_amount - real_invoicing
  end
  
  def estimated_profit
    initial_contract_amount - estimated_initial_costs
  end
  
  def real_profit
    real_invoicing - as_of_today_costs
  end
  
  def current_work
    (invoice_difference >= 0) ? BigDecimal.new("0") : invoice_difference.abs
  end
  
  def translated_revenue
    (invoice_difference < 0) ? BigDecimal.new("0") : invoice_difference.abs
  end
  
  # Scope totals
  def self.sum_total_cost(financial_year)
    for_year(financial_year).to_a.sum(&:total_cost)
  end
  
  def self.sum_real_invoicing(financial_year)
    for_year(financial_year).to_a.sum(&:real_invoicing)
  end
  
  def self.sum_invoice_difference(financial_year)
    for_year(financial_year).to_a.sum(&:invoice_difference)
  end
  
  def self.sum_estimated_profit(financial_year)
    for_year(financial_year).to_a.sum(&:estimated_profit)
  end
  
  def self.sum_real_profit(financial_year)
    for_year(financial_year).to_a.sum(&:real_profit)
  end
  
  def self.sum_current_work(financial_year)
    for_year(financial_year).to_a.sum(&:current_work)
  end
  
  def self.sum_translated_revenue(financial_year)
    for_year(financial_year).to_a.sum(&:translated_revenue)
  end
  
  # CSV
  def self.report_csv(accounting_items, separator = ",")
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      csv <<   ["No projet", 
                "Projet", 
                "Estimateur",
                "Gestionnaire de compte",
                "Chargé de projet",
                "Chef d'équipe",
                "Contrat initial",
                "Contrat après extra",
                "Coût initial prévu",
                "Coût exécuté à ce jour",
                "Inventaire sur chantier",
                "Coût à compléter",
                "Coût total",
                "Facturation au 31 déc.",
                "Facturation selon avancement réel",
                "Ecart de facturation",
                "Profit estimé",
                "Profit selon avancement réel",
                "Travaux en cours",
                "Revenus reportés"
              ]
              
      accounting_items.each do |ai|
        csv << [ai.project.contract_number, 
                ai.project.name,
                ai.project.estimator,
                ai.project.manager,
                ai.project.project_manager,
                ai.project.foreman,
                ai.initial_contract_amount,
                ai.with_extra_contract_amount,
                ai.estimated_initial_costs,
                ai.as_of_today_costs,
                ai.inventory_amount,
                ai.to_be_completed_costs,
                ai.total_cost,
                ai.invoiced_amount,
                ai.real_invoicing,
                ai.invoice_difference,
                ai.estimated_profit,
                ai.real_profit,
                ai.current_work,
                ai.translated_revenue
              ]
      end
      
    end
  end
  
  private
  def has_costs_validation
    errors.add_to_base("Veuillez vous assurer que vos couts totaux soit > 0") if self.total_cost <= 0
  end
end

