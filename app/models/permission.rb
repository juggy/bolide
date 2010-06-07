class Permission < ScopedByAccount
  PERMISSIONS = [
    # EVERYTHING
    'admin',
    
    # WHOLE MODULE ACCESS
    'access_accounting_infos',
    'access_configs',
    'access_estimation',
    'access_human_resource_infos',
    
    'create_calls', 
    'create_buildings', 
    'create_companies', 
    'create_contacts',
    'create_contracts',
    'create_messages',
    'create_and_update_equipments',
    'create_and_update_invoices',
    
    # DESTROY/MERGE
    'destroy_buildings',
    'destroy_companies',
    'destroy_contacts',
    'destroy_messages',
    'destroy_notes',
    'destroy_relations',
    'destroy_work_sheets',
    
    # SPECIAL
    'modify_teams',
    'modify_alert',
    'link_messages',
    'update_schedule',
    'show_schedule',
    'show_complete_reports',
    'show_concurator',
    'show_other_user_emails',
    'revert_project_state'
    ].freeze
  
  belongs_to :user
  
  validates_presence_of :user_id
  validates_inclusion_of :name, :in => PERMISSIONS
  validates_uniqueness_of :name, :scope => [:account_id, :user_id], :message => "must be unique"
end
