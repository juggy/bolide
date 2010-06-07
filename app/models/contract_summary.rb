# == Schema Information
# Schema version: 20090408154321
#
# Table name: contract_summaries
#
#  id                             :integer(4)      not null, primary key
#  project_id                     :integer(4)      
#  budget_income                  :decimal(10, 2)  default(0.0)
#  budget_roofer_cost             :decimal(10, 2)  default(0.0)
#  budget_driver_cost             :decimal(10, 2)  default(0.0)
#  budget_workshop_tinman_cost    :decimal(10, 2)  default(0.0)
#  budget_tinman_cost             :decimal(10, 2)  default(0.0)
#  budget_subcontrator_cost       :decimal(10, 2)  default(0.0)
#  budget_materials_cost          :decimal(10, 2)  default(0.0)
#  budget_machinery_cost          :decimal(10, 2)  default(0.0)
#  budget_general_conditions_cost :decimal(10, 2)  default(0.0)
#  budget_roofer_time             :decimal(10, 2)  default(0.0)
#  budget_driver_time             :decimal(10, 2)  default(0.0)
#  budget_workshop_tinman_time    :decimal(10, 2)  default(0.0)
#  budget_tinman_time             :decimal(10, 2)  default(0.0)
#  real_income                    :decimal(10, 2)  default(0.0)
#  real_roofer_cost               :decimal(10, 2)  default(0.0)
#  real_driver_cost               :decimal(10, 2)  default(0.0)
#  real_workshop_tinman_cost      :decimal(10, 2)  default(0.0)
#  real_tinman_cost               :decimal(10, 2)  default(0.0)
#  real_subcontrator_cost         :decimal(10, 2)  default(0.0)
#  real_materials_cost            :decimal(10, 2)  default(0.0)
#  real_machinery_cost            :decimal(10, 2)  default(0.0)
#  real_general_conditions_cost   :decimal(10, 2)  default(0.0)
#  real_roofer_time               :decimal(10, 2)  default(0.0)
#  real_driver_time               :decimal(10, 2)  default(0.0)
#  real_workshop_tinman_time      :decimal(10, 2)  default(0.0)
#  real_tinman_time               :decimal(10, 2)  default(0.0)
#  budget_extra_income            :decimal(10, 2)  default(0.0)
#  real_extra_income              :decimal(10, 2)  default(0.0)
#  updated_at                     :datetime        
#

class ContractSummary < ScopedByAccount
  
  belongs_to :project
  
  delegate :contract_number, :estimator, :manager, :project_manager, :project_director, :foreman, 
          :technology, :work_type, :building_type, :source, :was_service?, 
          :state, :state_name,
          :to => :project
  
  def project_name
    project.name
  end
  
  named_scope :for_finished_project, :conditions => "projects.state = 'finished'"
  named_scope :for_states, lambda {|st| st.blank? ? {} : {:conditions => ["projects.state in (?)", st]} }
  
  named_scope :min_start_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["projects.created_at >= ?", date] }
  }
  
  named_scope :max_start_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["projects.created_at <= ?", date] }
  }
  
  named_scope :min_work_end_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["projects.work_end_date >= ?", date] }
  }
  
  named_scope :max_work_end_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["projects.work_end_date <= ?", date] }
  }
  
  
  MAGIC_NET_PROFIT_VALUE = 27
  
  FIELDS_INFO =
  {
    "income"                  => _("Revenu"),
    "extra_income"            => _("Extra"),
    "total_income"            => _("Revenu"),
    "total_time"              => _("Heures Totales"),
    "roofer_cost"             => _("Dépense couvreur"),
    "driver_cost"             => _("Dépense chauffeur"),
    "workshop_tinman_cost"    => _("Dépense ferblantier atelier"),
    "tinman_cost"             => _("Dépense ferblantier chantier"),
    "subcontrator_cost"       => _("Dépense sous-traitant"),
    "materials_cost"          => _("Dépense matériaux"),
    "machinery_cost"          => _("Dépense machinerie"),
    "general_conditions_cost" => _("Conditions générales"),
    "roofer_time"             => _("Heures couvreur"),
    "driver_time"             => _("Heures chauffeur"),
    "workshop_tinman_time"    => _("Heures ferblantier atelier"),
    "tinman_time"             => _("Heures ferblantier chantier")
  }
  
  FIELDS = FIELDS_INFO.keys
  
  FIELDS_TRANSLATION = FIELDS_INFO.merge( 
  {
    "total_cost"          => _("Total des dépenses"),
    "total_mo_cost"          => _("Total des dépenses MO"),
    "total_material_cost"          => _("Total des dépenses Materiaux"),
    "gross_profit"        => _("Profit brut"),
    "net_profit"          => _("Profit net"),
    "production_rate"     => _("Production heure/carré"),
    "roofer_mean_cost"    => _("Coût moyen horaire couvreur"),
    "machinery_mean_cost" => _("Coût moyen horaire machinerie"),
    "hourly_profit"       => _("Profit par heure"),
    "profit_rate"         => _("Taux profit"),
    "area"                => _("Superficie")

  })
  
  # Helper for importation
  FIELDS.each do |field|
    eval "
      def #{field}=(values)
        self.budget_#{field}, self.real_#{field} = values
      end
    "
  end
  
  def real_income=(value)
    write_attribute(:real_income, value.to_d.abs)
  end
  
  def real_extra_income=(value)
    write_attribute(:real_extra_income, value.to_d.abs)
  end
  
  def budget_total_income
    self.budget_income + self.budget_extra_income
  end
  
  def real_total_income
    self.real_income + self.real_extra_income
  end
  
  def budget_total_cost
    self.budget_roofer_cost +
    self.budget_driver_cost +
    self.budget_workshop_tinman_cost +
    self.budget_tinman_cost +
    self.budget_subcontrator_cost +
    self.budget_materials_cost +
    self.budget_machinery_cost +
    self.budget_general_conditions_cost
  end
  
  def real_total_cost
    self.real_roofer_cost +
    self.real_driver_cost +
    self.real_workshop_tinman_cost +
    self.real_tinman_cost +
    self.real_subcontrator_cost +
    self.real_materials_cost +
    self.real_machinery_cost +
    self.real_general_conditions_cost
  end
  
  def budget_total_mo_cost
    self.budget_roofer_cost +
    self.budget_driver_cost +
    self.budget_workshop_tinman_cost +
    self.budget_tinman_cost
  end
  
  def real_total_mo_cost
    self.real_roofer_cost +
    self.real_driver_cost +
    self.real_workshop_tinman_cost +
    self.real_tinman_cost
  end
  
  def budget_total_material_cost
    self.budget_materials_cost
  end
  
  def real_total_material_cost
    self.real_materials_cost
  end
  
  def budget_gross_profit
    self.budget_total_income - self.budget_total_cost
  end
  
  def real_gross_profit
    self.real_total_income - self.real_total_cost
  end
  
  def budget_net_profit
    self.budget_total_income - 
    self.budget_total_cost - 
    ([self.budget_roofer_time,
      self.budget_driver_time,
      self.budget_workshop_tinman_time,
      self.budget_tinman_time
      ].sum * MAGIC_NET_PROFIT_VALUE )
  end
  
  def real_net_profit
    self.real_total_income - 
    self.real_total_cost - 
    ([self.real_roofer_time,
      self.real_driver_time,
      self.real_workshop_tinman_time,
      self.real_tinman_time
      ].sum * MAGIC_NET_PROFIT_VALUE )
  end
  
  def budget_total_time
    [ self.budget_roofer_time,
      self.budget_driver_time,
      self.budget_workshop_tinman_time,
      self.budget_tinman_time
      ].sum
  end
  
  def real_total_time
    [ self.real_roofer_time,
      self.real_driver_time,
      self.real_workshop_tinman_time,
      self.real_tinman_time
      ].sum
  end
  
  FIELDS.concat(["total_cost","total_mo_cost","total_material_cost","gross_profit","net_profit", "total_income", "total_time"]).each do |field|
    eval "
      def variation_#{field}
        self.real_#{field} - self.budget_#{field}
      end
  "
  end
  
  def budget_roofer_mean_cost
    self.budget_roofer_cost / self.budget_roofer_time rescue 0.0
  end
  
  def real_roofer_mean_cost
    self.real_roofer_cost / self.real_roofer_time rescue 0.0
  end
  
  def budget_machinery_mean_cost
    self.budget_machinery_cost / self.budget_roofer_time rescue 0.0
  end
  
  def real_machinery_mean_cost
    self.real_machinery_cost / self.real_roofer_time rescue 0.0
  end
  
  def budget_hourly_profit
    self.budget_gross_profit / self.budget_roofer_time rescue 0.0
  end
  
  def real_hourly_profit
    self.real_gross_profit / self.real_roofer_time rescue 0.0
  end
  
  def budget_profit_rate
    (self.budget_gross_profit / self.budget_total_income) * 100.0 rescue 0.0
  end
  
  def real_profit_rate
    (self.real_gross_profit / self.real_total_income) * 100.0 rescue 0.0
  end
  
  
  ##### Area related 
  
  def budget_area
    project.area
  end
  
  def real_area
    project.area_real
  end
  
  def budget_hourly_area
    (self.budget_roofer_time / self.budget_area) * 100.0 rescue 0.0
  end
  
  def real_hourly_area
    (self.real_roofer_time / self.real_area) * 100.0 rescue 0.0
  end
  
  def budget_income_to_area
    (self.budget_total_income / self.budget_area) rescue 0.0
  end
  
  def real_income_to_area
    (self.real_total_income / self.real_area) rescue 0.0
  end
  
  def self.report_contract_stats_csv(data, separator = ",")
    
    fields = [
      ["total_income", :money],
      ["total_cost", :money],
      ["total_material_cost", :money],
      ["gross_profit", :money],
      ["total_time", :time]
      ]
      
      csv_header = []
      csv_row = []
      
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      csv_header <<   ["No projet", 
                "Projet", 
                "Statut", 
                "Estimateur",
                "Gestionnaire de compte",
                "Chargé de projet",
                "Chef d'équipe",
                "Directeur de projet",
                "Technologie",
                "Type de travaux",
                "Source"
                ]
              
     for field in fields 
       csv_header << "#{ContractSummary::FIELDS_TRANSLATION[field[0]]} Budget"
       csv_header << "#{ContractSummary::FIELDS_TRANSLATION[field[0]]} Réel"
       csv_header << "#{ContractSummary::FIELDS_TRANSLATION[field[0]]} Écart"
     end
      
      csv << csv_header.flatten
    
      # data rows       
      data.each do |d|
        csv_row = []
        csv_row << [d.project.contract_number, 
                d.project.name,
                d.state_name,
                d.project.estimator,
                d.project.manager,
                d.project.project_manager,
                d.project.foreman,
                d.project.project_director,
                d.project.technology,
                d.project.work_type,
                d.project.source]
                
        for field in fields 
          csv_row << "#{d.send("budget_#{field[0]}")}"
          csv_row << "#{d.send("real_#{field[0]}")}"
          csv_row << "#{d.send("variation_#{field[0]}")}"
        end
        csv << csv_row.flatten
      end
      
    end
  end
  
end
