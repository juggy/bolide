class Signup
  
  def self.create(params = {})
    [:subdomain, :first_name, :last_name, :login, :email, :password, :company_name].each do |key|
      raise "Missing #{key} to create new account" if !params.has_key?(key)
    end
    
    Account.transaction do
      
      account = Account.create!(:subdomain => params[:subdomain])
      Account.current_account = account
      
      admin = User.create!( 
            params.except(:subdomain, :company_name).merge(
              {:system_user => true, :password_confirmation => params[:password]} )
          )
      admin.permissions.create!(:name => 'admin')
      
      owner_company = Company.create!(:name => params[:company_name])
      admin_contact = Contact.create!( params.only(:first_name, :last_name, :company_name).merge({:user_id => admin.id}) )
      
      account.update_attributes!(:company_id => owner_company.id)
      
      
      create_seed_data
      
    end
    
  end
  
  protected
  
  def self.seed(model, values)
    values.each {|value| model.find_or_create_by_name(value) }
  end
  
  def self.create_seed_data
    roles = 
    {
      :list =>
        [
          {:name => "estimateur"},
          {:name => "gestionnaire de compte"},
          {:name => "chargé de projet"},
          {:name => "chef d'équipe"},
          {:name => "couvreur"},
          {:name => "ferblantier"},
          {:name => "directeur de projet"},
          {:name => "responsable documents"},
          {:name => "responsable soumission"}
        ],

      # :notification =>
      #   [
      #     {:name => "nouvelle demande"},
      #     {:name => "appel de service"}
      #   ]
    }

    roles.each do |category, role_list|
      role_list.each do |role_attrs|
        role = Role.find_or_initialize_by_name(role_attrs[:name])
        role.description = role_attrs[:description]
        role.category = category.to_s
        role.save
      end
    end

    seed CallCommSource,  ["Téléphone","Fax","Email","Courrier"]
    seed CallSource,      ["Appel d'offres","Invitation","Internet"]
    seed CallType,        ["Estimation", "Information", "Expertise"]
    seed WorkType,        ["Construction neuve", "Modification" ]
    seed Technology,      []
    seed Region,          ["00 - Extérieur du Québec",
                           "01 - Iles de la Madeleine",
                           "02 - Bas-Saint-Laurent - Gaspésie",
                           "03 - Saguenay - Lac St-Jean",
                           "04 - Québec",
                           "06 - Mauricie - Bois-Francs",
                           "07 - Estrie ",
                           "08 - Grand Montréal",
                           "09 - Outaouais",
                           "10 - Abitibi-Témiscamingue",
                           "11 - Côte-Nord",
                           "13 - Baie-James"]

    seed BuildingType,    ["Génie civil", "Industriel", "Industriel lourd", "Commercial", "Institutionnel", "Résidentiel"]
    seed TcCompany,       []

    #seed ContractType,    ["SEC", "SEC+", "SEC++", "PEP"]
    seed ContractType,    ["base"]
    seed ActivityCategory, ["Appel", "Meeting", "Soumission"]  # ["processus"]
    seed ProspectStatus,  ["chaud","froid"]
    
    seed Department,      ["production"]
  end
  
end