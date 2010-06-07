# == Schema Information
# Schema version: 20090408154321
#
# Table name: projects
#
#  id                       :integer(4)      not null, primary key
#  name                     :string(255)     
#  state                    :string(30)      
#  call_number              :integer(4)      
#  quote_number             :string(20)      
#  contract_number          :string(20)      
#  building_id              :integer(4)      
#  client_id                :integer(4)      
#  estimator_id             :integer(4)      
#  created_by_id            :integer(4)      
#  created_at               :datetime        
#  updated_at               :datetime        
#  close_quote_by           :datetime        
#  bsdq_date                :boolean(1)      
#  manager_id               :integer(4)      
#  source_id                :integer(4)      
#  work_type_id             :integer(4)      
#  technology_id            :integer(4)      
#  region_id                :integer(4)      
#  building_type_id         :integer(4)      
#  tc_company_id            :integer(4)      
#  area                     :integer(4)      
#  quoted_roofer_time       :integer(4)      
#  quoted_amount            :decimal(10, 2)  default(0.0)
#  project_manager_id       :integer(4)      
#  foreman_id               :integer(4)      
#  work_start_date          :date            
#  work_end_date            :date            
#  roof_section             :string(255)     
#  prospect_status_id       :integer(4)      
#  possible_work_start_date :string(255)     
#  caution                  :string(255)     
#  addenda                  :string(255)     
#  documenter_id            :integer(4)      
#  service_field            :string(255)     
#  contract_field           :string(255)     
#  tinman_field             :string(255)     
#  caution_type_id          :integer(4)      
#  height                   :integer(4)      
#  po_number                :string(255)     
#  area_real                :integer(4)      
#  contract_id              :integer(4)      
#  duplicate_id             :integer(4)      
#  ladder                   :boolean(1)      
#  won_date                 :datetime        
#  quote_date               :datetime        
#  visit_date               :datetime        
#  service                  :boolean(1)      
#  system_composition       :text            
#  recq_comments            :text            
#  bridging_id              :integer(4)      
#  estimated_project_length :string(255)     
#

require 'fastercsv'
# require 'gettext/rails'

module StateMachineExtension
  attr_accessor :state_categories, :states
  def state_category(cat, states)
    @state_categories ||= {}
    @states ||= []
    @states.concat(states).uniq!
    @state_categories[cat] = states
    named_scope cat.to_sym, :conditions => ["state in (?)",states.map(&:to_s)]
    named_scope "not_#{cat}".to_sym, :conditions => ["state not in (?)",states.map(&:to_s)]
  end
end

class Project < ScopedByAccount
  
  strip_attributes! :only => [:quote_number,:contract_number,:roof_section,:possible_work_start_date]
    
#  acts_as_solr :fields => [:call_number, :quote_number, :contract_number, :display_name, :po_number]
  define_index do
    indexes :name, call_number, "CONCAT('A', call_number)", quote_number, contract_number, po_number
    set_property :delta => true
    has :account_id
  end
  
  acts_as_taggable
  acts_as_audited
  
  def all_audits
    all = []
    all.concat audits
    all.concat work_sheets.collect {|a| a.audits} 
    all.flatten.reject {|a| 
      a.changes.is_a?(String) || # strange serialization bug
      (a.changes || {}).keys.size == 0
    }.sort_by(&:created_at).reverse
  end
  
  extend StateMachineExtension
  
  created_by_user
  
  delegate :full_instructions, :to => :building
  
  belongs_to :building
  belongs_to :client,     :class_name => "Company", :foreign_key => :client_id
  belongs_to :department
  
  belongs_to :estimator,  :class_name => "User",    :foreign_key => :estimator_id
  belongs_to :visitor,  :class_name => "User",    :foreign_key => :visitor_id
  belongs_to :manager,  :class_name => "User",    :foreign_key => :manager_id
  belongs_to :project_manager,  :class_name => "User",    :foreign_key => :project_manager_id
  belongs_to :project_director,  :class_name => "User",    :foreign_key => :project_director_id
  belongs_to :foreman,  :class_name => "User",    :foreign_key => :foreman_id
  belongs_to :estimation_assistant, :class_name => "User", :foreign_key => :estimation_assistant_id
  belongs_to :documenter,  :class_name => "User",    :foreign_key => :documenter_id
  
  belongs_to :contract
  has_one :call
  has_one :contract_summary
  def get_contract_summary
    self.contract_summary || self.build_contract_summary
  end
  
  has_many :work_sheets
  
  has_many :activities
  has_many :tasks
  has_many :notes, :order => 'updated_at desc'
  has_many :state_changes
  
  has_many :involvements
  has_many :involved_parties, :through => :involvements, :class_name => 'Party', :foreign_key => 'party_id', :source => 'party'

  belongs_to :source, :class_name =>  "CallSource"
  belongs_to :work_type
  belongs_to :technology
  belongs_to :region
  belongs_to :building_type
  belongs_to :bridging
  belongs_to :tc_company
  belongs_to :prospect_status
  belongs_to :caution_type
  
  has_many :warranty_infos, :attributes => true, :discard_if => :blank?, :dependent => :destroy
  
  has_many :accounting_items, :order => "financial_year DESC"
  
  has_many :bidders, :dependent => :destroy, :order => 'position, bid'
  
  has_many :time_entries
  
  has_many :linked_messages
  
  validate :require_estimator_for_quote_state
  validate :require_close_date_for_prospect_state
  validate :require_work_end_date_when_production_ends
  validate :required_fields_for_contract_end_docs
  
  named_scope :for_estimator, lambda {|user| user.blank? ? {} : {:conditions => ["projects.estimator_id = ?", user]} }
  named_scope :for_manager, lambda {|user| user.blank? ? {} : {:conditions => ["projects.manager_id = ?", user]} }
  named_scope :for_documenter, lambda {|user| user.blank? ? {} : {:conditions => ["projects.documenter_id = ?", user]} }
  named_scope :for_project_manager, lambda {|user| user.blank? ? {} : {:conditions => ["projects.project_manager_id = ?", user]} }
  named_scope :for_state, lambda {|st| st.blank? ? {} : {:conditions => ["projects.state = ?", st]} }
  named_scope :for_states, lambda {|st| st.blank? ? {} : {:conditions => ["projects.state in (?)", st]} }
  named_scope :for_prospect_status, lambda {|st| st.blank? ? {} : {:conditions => ["projects.prospect_status_id = ?", st]}}
  
  named_scope :visit_only, lambda {|v| v.blank? ? {} : {:conditions => "visit_date is not null", :order => :visit_date} }
  
  #TODO: need to cache on the model the real quote date
  named_scope :min_quote_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["close_quote_by >= ?", date] }
  }
  #TODO: extract helper for date filtering
  named_scope :max_quote_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["close_quote_by <= ?", date] }
  }
  
  named_scope :min_creation_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["created_at >= ?", date] }
  }
  named_scope :max_creation_date, lambda {|d|
    return {} if d.blank?
    date = d.to_date rescue nil
    return {} unless date
    return {:conditions => ["created_at <= ?", date] }
  }
  
  named_scope :client_building_contracts, lambda {|ct| 
    return {} if ct.blank?
    return {:joins => "inner join parties client on projects.client_id = client.id 
                       inner join parties building on projects.building_id = building.id",
            :select => "projects.*", 
            :conditions => ["building.contract_type_id = ? or client.contract_type_id = ?",ct,ct]} 
  }
  
  def self.active_list_to_csv(projects = self.active, separator = ",")
    
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      csv <<   ["Date PO",        "No projet",      "Client",           "Nom",              "Étapes des travaux", 
                "Technologie",    "Superficie pc",  "Nb hres estimées", "Montant",
                "Estimateur",     "Gestionnaire",   "Chargé de projet", "Chef d'équipe",
                "Resp. documents","Projet service", "Projet contrat",   "Projet ferblanterie",
                "Date début",     "Date fin",       "Notes"]
      # data rows
      projects.each do  |p|
        csv << ["#{p.won_date.to_date.localize(:default) if p.won_date}", p.contract_number, "#{p.client.name if p.client}", p.display_name,    p.state_name,
                "#{p.technology.name if p.technology}" , "#{p.area}", "#{p.quoted_roofer_time}", "#{p.quoted_amount}",
                "#{p.estimator.full_name if p.estimator}", "#{p.manager.full_name if p.manager}", "#{p.project_manager.full_name if p.project_manager}","#{p.foreman.full_name if p.foreman}",
                "#{p.documenter.full_name if p.documenter}",p.service_field,p.contract_field,p.tinman_field,
                "#{p.work_start_date.to_date.localize(:default) if p.work_start_date}", "#{p.work_end_date.to_date.localize(:default) if p.work_end_date}", "#{p.notes.first.body if p.notes.size > 0}" ]
      end
    end
  end
  
  def self.quote_archive_to_csv( projects, separator = ",")
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      csv <<   ["No Soumission",
                "Immeuble",
                "Section",
                "Ville",
                "Type de travaux",
                "Estimateur",
                "Date fermeture",
                "No Appel"
              ]

      projects.each do |p|
        csv << [p.quote_number,
                p.building.name,
                p.roof_section,
                p.building.address.city,
                p.work_type,
                p.estimator.to_s,
                "#{p.close_quote_by.to_date.localize(:default) if p.close_quote_by}",
                p.call_number
              ]
      end
    end
  end
  
  def call_number
    num = read_attribute(:call_number)
    num.present? ? "A#{num}" : ""
  end
  
  # TODO: helper for state_changes date
  # NOTE: These date function are really expensive to call and should only be used for reports
  def find_won_date
    if check_was_won?
      sc = state_changes.find_by_title('won', :order => 'id desc')
      sc ? sc.created_at : nil
    end
  end
  
  def check_was_won?
    counter = 0
    self.state_changes.each do |stc|
       counter += 1 if ['quoted', 'waiting'].include?(stc.old_state) && ['won','service'].include?(stc.new_state)
       counter -= 1 if ['won','service'].include?(stc.old_state) && ['quoted', 'waiting'].include?(stc.new_state)
    end
    counter > 0
    #self.state_changes.any? {|st| ['quoted', 'waiting'].include?(st.old_state) && ['won','service'].include?(st.new_state) }
  end
  
  def was_won?
    !won_date.nil?
  end
  
  def find_quote_date
    sc = state_changes.find_by_title('quoted', :order => 'id desc')
    sc ? sc.created_at : nil
  end
  
  # def find_visit_date
  #   task = tasks.find_by_body("Visite de chantier")
  #   (task && task.scheduled_date) ? task.scheduled_date.time : nil
  # end
  
  def real_quoted_amount
    get_contract_summary.budget_income
  end
  
  def candidate_contracts
    cont = [nil]
    cont.concat client.contracts if client && client.contracts.size > 0
    cont << building.contract if building && building.contract
    cont.uniq
  end
  
  def has_accounting_items?
    accounting_items.size > 0
  end
  ## Duplicate mgmt
  
  belongs_to :duplicate, :class_name => "Project", :foreign_key => "duplicate_id"
  def possible_duplicates
    self.building ? self.building.projects.not_closed.select {|p| p.id != self.id } : []
  end
  
  def close_duplicate!(project)
    self.state = "closed"
    self.duplicate_id = project.id
    self.save
  end

  def remove_duplicate_flag!(project)
    self.duplicate_id = nil
    self.save
  end
  
  def duplicate?
    duplicate_id != nil
  end
  
  
  
  
  def new_call?
    self.state == "new_call"
  end
  
  def is_service?
    self.state == "service"
  end
  
  def forward_transition?(from, to)
    Transitions[from.to_sym].include?(to.to_sym)
  end
  
  # TODO: ugly helper method to cache projects service
  def was_service?
    counter = 0
    service_states = ["service"]
    self.state_changes.each do |stc|
      if service_states.include?( stc.new_state ) || service_states.include?( stc.old_state )
        if forward_transition?(stc.old_state,stc.new_state)
          counter += 1
        else
          counter -= 1
        end
      end
    end
    is_service? || counter > 0
  end
  
  def was_quoted?
    !quote_number.blank?
  end
  
  def invoiced_amount
    self.work_sheets.proxy_target.sum {|ws| ws.invoices.proxy_target.sum {|i| i.invoice_amount } }
  end
  
  def is_defined?
    client && building
  end
  
  # TODO: cache in db if it becomes a performance problem
  def list_sort_id
    sort_state_id = service? ? "000" : ("%3d" % (StateOrder.index(self.state.to_sym) + 10))
    "#{sort_state_id}#{self.created_at.strftime("%Y%m%d")}"
  end
  
  def display_name
    self.name
  end
  
  def first_note
    notes.find(:first, :order => 'id asc').body rescue ""
  end
  
  def make_display_name
    unless @display_name 
      name = []
      name << "DOUBLON" if duplicate?
      name << building.name if building
      name << building.address.city if building
      name << work_type.name if work_type
      name << roof_section unless roof_section.blank?
      name << created_at.strftime("%y") if created_at
      @display_name = name.compact.join(", ")
    end
    @display_name
  end
  
  def display_name_with_numbers
    numbers = [self.call_number,self.contract_number].compact.join("/")
    [numbers,display_name].compact.join(" - ")
  end
  
  def quick_search_name
    display_name_with_numbers + " (#{self.state_name} #{created_at.to_date.localize})"
  end
  
  def to_s
    display_name
  end
  
  def priority?
    contract && contract.is_priority?
  end
  
  def building_contract_id=(cid)
    self.contract_id = cid
    if self.building && !self.building.contract?
      building.contract_id = cid
      building.contract_type_id = self.contract.contract_type_id
      building.save
    end
  end
  
  def self.auto_complete_search(query)
    no = query.downcase.strip
    self.find(:all, :conditions => ["LOWER(name) LIKE ? OR call_number LIKE ? OR quote_number LIKE ? OR contract_number LIKE ? OR po_number LIKE ?", "%#{no}%", "#{no}%","#{no}%","#{no}%","#{no}%"], :limit => 10)
  end
  
  
  ### Callbacks
  
  def after_initialize
    if self.new_record?
      self.state ||= "new_call"
    end
    @previous_state = self.state
    @previous_category_state = self.category
    # TODO: default close_quote_by on creation?
  end
  
  def after_create
    self.tasks.create({ :body => 'Nouvelle demande', :activity_category_id => PROCESS_CATEGORY_ID })
  end
  
  attr_accessor :create_new_base_contract
  
  def create_base_contract
    if self.contract_id.nil? && self.building && self.client && !self.building.contract?
      self.contract = Contract.create(
              :contract_type => ContractType.find_by_name("base"), 
              :client => self.client, 
              :building_ids => [self.building.id])
    end
  end
  
  def before_save
    create_base_contract if @create_new_base_contract == "true"
    
    self.visitor_id ||= self.estimator_id
    
    if self.building
      self.building_type_id ||= self.building.building_type_id
      self.region_id ||= self.building.region_id
      self.technology_id ||= self.building.technology_id
      self.height ||= self.building.height
    end
    
    if self.contract && self.building
      self.tc_company_id ||= self.building.tc_company_id
    end
      
    if manager_id.nil? && client && client.manager
      self.manager_id = client.manager.id
    end
    if entering_state?( :quote_in_progress )
      self.estimation_assistant_id ||= User.current_user.id
    end
    if entering_state?( :quote_in_progress )
      self.quote_number = "#{Time.now.strftime("%y")}-#{"%04d"%SystemSetting.next_quote_number}" if self.quote_number.blank?
    end
    if entering_state?( :production )
      self.documenter_id ||= User.current_user.id
      # self.project_director_id ||= self.manager_id
    end
    write_attribute(:name, make_display_name)
    
    unless new_record?
      write_attribute(:won_date, find_won_date)
      write_attribute(:quote_date, find_quote_date)
      # write_attribute(:visit_date, find_visit_date)
      write_attribute(:service, was_service?)
    end
    
    if self.service?
      self.use_building_contract_info
    end
    
    if self.quoted_amount_changed?
      update_bid_positions
    end
    
    true
  end
  
  def update_bid_positions
    if self.bidders.size > 0
      tc_bid = nil
      bidders = self.bidders
    
      if self.quoted_amount
        tc_bid = Bidder.new(:company_id => SystemSetting.owner_id, :bid => self.quoted_amount)
        bidders = [tc_bid].concat(bidders)
      end
    
      bidders = bidders.sort_by(&:bid)
      bidders.each_with_index do |b,index|
        if b == tc_bid
          Project.update_all(['bid_position=?', index+1], ['id=?', self.id])
        else
          Bidder.update_all(['position=?', index+1], ['id=?', b.id])
        end
      end
    elsif self.bid_position
      Project.update_all(['bid_position=?', nil], ['id=?', self.id])
    end
  end
  
  def use_building_contract_info
    self.contract_number = self.building.icc_ref if self.building.icc_ref.present? && !(self.contract_number && self.contract_number.match(/[a-zA-Z]/))
    self.tc_company_id ||= self.building.tc_company_id
  end
  
  # We create a new note when the state has changed
  # @previous_state is used to track this
  def after_save
    if @previous_state.to_s != self.state.to_s
      create_transition_tasks
      self.state_changes.create!(:old_state => @previous_state, :new_state => self.state,
                        :user_id => User.current_user.id)
                        
      @previous_state = self.state.to_s
      @previous_category_state = self.category
    end
  end
  
  state_category :call, [:new_call]
  state_category :quote_in_progress, [:quote_in_progress]
  state_category :prospect, [:quoted,:waiting]
  state_category :active, [:service, :production, :contract_end_docs, :final_verification]
  state_category :closed, [:not_quoted,:lost,:cancelled, :finished, :closed]
  state_category :service, [:service]
  
  # TODO: use it?
  Transitions = {
    :new_call => [:quote_in_progress, :not_quoted, :service, :closed],
    :quote_in_progress => [:quoted, :cancelled, :not_quoted],
    :quoted => [ :waiting, :production, :service, :lost, :cancelled],
    :waiting => [ :production, :lost, :cancelled],
    
    :service => [:finished, :cancelled],
    :not_quoted => [],
    :lost => [],
    :finished => [],
    :cancelled => [],
    :closed => [],
    
    :won => [:production],
    :production => [:contract_end_docs],
    :contract_end_docs => [:final_verification],
    :final_verification => [:finished]
  }
  
  StateOrder = [:new_call, :quote_in_progress, :quoted, :waiting, :won, :production, :approval, :production_end, :contract_end_docs, :final_verification, :finished, :closed, :not_quoted, :cancelled, :lost]
  
  def self.inverse_transitions
    inverse = {}
    Transitions.keys.each {|k| inverse[k] = [] }
    Transitions.each do |key, values|
      values.each do |value|
        arr = inverse[value]
        arr << key
      end
    end
    inverse
  end
  
  InverseTransitions = Project.inverse_transitions.freeze
    
  
  def category
    Project.state_categories.each do |key, value|
      return key if value.include?(self.state.to_sym)
    end
    nil
  end
  
  def state_name
    Project.states_name[self.state]
  end
  
  def localized_state
    state_name
  end
  
  # TODO: move yo fr-CA.yml ???
  def self.states_name
    HashWithIndifferentAccess.new( {
      :new_call          => _("nouvelle demande"),
      :to_quote          => _("à soumissionner"), # DEAD, keep as some elements are still linked to it
      :not_quoted        => _("ne pas soumissionner"),
      :preparation       => _("en préparation"), # DEAD
      :quote_in_progress => _("en soumission"),
      :quoted            => _("soumissionné"),
      :won               => _("gagné"), # DEAD, use prospect status instead
      :service           => _("service"),
      :lost              => _("perdu"),
      :cancelled         => _("annulé"),
      :waiting           => _("en attente"),
      :finished          => _("terminé"),
      :question          => _("question"), #DEAD
      :closed            => _("fermé"),
      
      :planning          => _("planning"), # DEAD, keep as some elements are still linked to it
      :production        => _("production"),
      :approval          => _("acceptation"), # DEAD, keep as some elements are still linked to it
      :production_end    => _("fin de projet"), # DEAD, keep as some elements are still linked to it
      :contract_end_docs => _("document fin contrat"),
      :final_verification => _("contrôle final")
    } )
  end
  
  def next_state_select_options(user = nil)
    next_states = nil
    
    admin_only_when_finished = (self.state.to_sym == :finished && user && (user.has_permission?('admin') ) )
    advanced_user_otherwise = (self.state.to_sym != :finished && user && ( user.has_permission?('revert_project_state') ) )
    
    if admin_only_when_finished || advanced_user_otherwise
      next_states = InverseTransitions[self.state.to_sym].concat( [self.state.to_sym].concat( Transitions[self.state.to_sym] ) ).uniq
    else
      next_states = [self.state.to_sym].concat( Transitions[self.state.to_sym] ).uniq
    end
    
    next_states.map {|s| [Project.states_name[s], s.to_s] }
  end
  
  def self.state_select_options
    self.states.map {|s| [self.states_name[s], s.to_s] }
  end
  
  def created_at_fr
    created_at
  end
  
  #TODO: helper for dates
  def created_at_fr=(time)
    write_attribute(:created_at, fr_time(time) )
  end
  
  # Override to support french dates
  def close_quote_by=(time)
    write_attribute(:close_quote_by, fr_time( time ) )
  end
  
  def visit_date=(time)
    write_attribute(:visit_date, fr_time( time ) )
  end
  
  def work_end_date=(time)
    write_attribute(:work_end_date, fr_time( time ))
  end
  
  def work_start_date=(time)
    write_attribute(:work_start_date, fr_time( time ))
  end
  
  protected
  
  # Custom validations
  def require_estimator_for_quote_state
    if entering_state?(:quote_in_progress)
      errors.add( :estimator_id, _("Il faut spécifier un estimateur!") ) unless self.estimator
    end
  end
  
  def require_close_date_for_prospect_state
    if entering_category?(:prospect)
      errors.add( :close_quote_by, _("Il faut spécifier la date de fermeture lorsque le projet devient un prospect!") ) unless self.close_quote_by
    end
  end
  
  def required_fields_for_contract_end_docs
    if entering_state?(:contract_end_docs) || self.state.to_sym == :contract_end_docs
      #avant de progresser au statut fin de contrat (apres production),  les champs suivants doivent absolument etre spécifié: date de début et fin des travaux (regarder les interventions), type de travaux, type immeuble, technologie, gestionnaire, chargé, estimateur, chef équipe, source
      errors.add( :work_type_id,      _("Il faut spécifier le type de travaux!") )  unless self.work_type_id
      errors.add( :building_type_id,  _("Il faut spécifier le type d'immeuble!") )  unless self.building_type_id
      errors.add( :technology_id,     _("Il faut spécifier la technologie!") )      unless self.technology_id
      errors.add( :source_id,         _("Il faut spécifier la source!") )           unless self.source_id
      errors.add( :manager_id,        _("Il faut spécifier un gestionnaire!") )     unless self.manager_id
      errors.add( :project_manager_id,_("Il faut spécifier un chargé de projet!") ) unless self.project_manager_id
      errors.add( :estimator_id,      _("Il faut spécifier un estimateur!") )       unless self.estimator_id
      errors.add( :foreman_id,        _("Il faut spécifier un chef d'équipe!") )    unless self.foreman_id
    end
  end
  
  def require_work_end_date_when_production_ends
    if state_transition?(:production, :contract_end_docs )
      update_work_dates
      errors.add( :work_end_date, _("Il faut spécifier la date de fin des travaux lorsque la production est terminée!") ) unless self.work_end_date
    end
  end
  
  def update_work_dates
    ws_ids = self.work_sheets.collect(&:id)
    self.work_start_date ||= Intervention.minimum(:date, :conditions => {:work_sheet_id => ws_ids})
    self.work_end_date ||= Intervention.maximum(:date, :conditions => {:work_sheet_id => ws_ids})
  end
  
  def category_transition?(old_cat, new_cat)
    @previous_category_state == old_cat && self.category == new_cat
  end
  
  def entering_category?(new_cat)
    @previous_category_state.to_s != new_cat.to_s && self.category.to_s == new_cat.to_s
  end
  
  def state_transition?(old_state, new_state)
    @previous_state.to_s == old_state.to_s && self.state.to_s == new_state.to_s
  end
  
  def entering_state?(new_state)
    @previous_state.to_s != new_state.to_s && self.state.to_s == new_state.to_s
  end
  
  # Called after save when state changed
  def create_transition_tasks
    return unless Account.current_account.tc?
    
    #task_category = ActivityCategory.find_by_name('processus')
    self.tasks.active.for_category(PROCESS_CATEGORY_ID).each {|t| t.destroy unless t.user_id }
    
    defaults = { :activity_category_id => PROCESS_CATEGORY_ID }
    next_position = 0
    ordered_defaults = lambda { defaults.merge( :position => (next_position += 1 )) }
    
    if state_transition?( :new_call, :quote_in_progress )
      Notification.new_to_quote(self)
    end
    
    if entering_state?( :quote_in_progress )
      # supervisor = Role.find_by_name('directeur ventes')
      # supervisor = supervisor ? supervisor.users.first : nil
      # supervisor_id = supervisor ? supervisor.id : nil
      # FIXME: hard coded for now while I rethink how to properly handle auto created tasks
      supervisor_id = 26
      plan_user_id = 65
            
      quote_date = close_quote_by ? close_quote_by : ( (Time.now + 7.days).at_beginning_of_day + 16.hours )
      
      self.tasks.create( 
        [
           {:body => _("Visite de chantier"),         :party_id => self.building_id, :user_id => self.visitor_id },
           {:body => _("Inspection") },
           {:body => _("Approbation du système") },
           {:body => _("Plan/relevé des déficiences"),  :user_id => plan_user_id, :scheduled_at => (quote_date - 1.days) },
           {:body => _("Estimation"),                 :user_id => self.estimator.id, :scheduled_at => quote_date },
           {:body => _("Offre de service/soumission"), :user_id => User.current_user.id, :scheduled_at => quote_date },
           {:body => _("Revision"),                   :user_id => supervisor_id, :scheduled_at => (quote_date - 1.days)}
        ].collect {|t| t.merge( ordered_defaults.call ) }
      )
    end
    
    if entering_state?( :quoted )
      self.tasks.create( {:body => _("Suivi"), :user_id => self.estimator.id }.merge(defaults) )
    end
    
    if entering_state?( :service )
      Notification.new_intervention(self)
      # TODO: add link to print feuillle de travail
      
      # Old Activities, replaced by work sheet workflow
      # self.tasks.create([
      #   { :body => _("Céduler les travaux") },
      #   { :body => _("Exécuter les travaux") },
      #   { :body => _("Facturer les travaux") },
      #   { :body => _("Acceptation final du chantier") }
      # ].collect {|t| t.merge( ordered_defaults.call ) } )
    end
    
    # Old activities, replaced by states
    # if category_transition?( :quote_in_progress, :active) || category_transition?( :prospect, :active)
    #   self.tasks.create([
    #     {:body => "Céduler les travaux" },
    #     {:body => "Préparer les document de productions" },
    #     {:body => "Préparer les documents adminsitratifs" },
    #     {:body => "Préparer les documents d'approvisionnement" },
    #     {:body => "Faire les achats" },
    #     {:body => "Effectuer le pré-meeting" },
    #     {:body => "Exécuter les travaux de toitures" },
    #     {:body => "Exécuter les travaux de ferblanterie" },
    #     {:body => "Coordonner les travaux des sous-traitant" },
    #     {:body => "Contrôler la production" },
    #     {:body => "Facturer les travaux" },
    #     {:body => "Accepter la facture" },
    #     {:body => "Acceptation provisoire du chantier" },
    #     {:body => "Exécution de travaux mineur sur chantier" },
    #     {:body => "Préparation de document de fin de projet" },
    #     {:body => "Acceptation final du chantier" },
    #     {:body => "Contrôle final du projet(contrat)"}
    #   ].collect {|t| t.merge( ordered_defaults.call ) })
    # end
  end
end
