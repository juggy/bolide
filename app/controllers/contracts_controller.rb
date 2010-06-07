class ContractsController < ResourceController::Base
  require_permission 'create_contracts', :only => [:new, :create, :destroy]
  
  # index.wants.html { 
  #   @contracts = end_of_association_chain.paginate :page => params[:page], :include => [:client], :order => 'parties.name'
  # }
  
  def show
    load_object
    redirect_to contracts_company_url( :id => @contract.client)
  end
  
  create.success.wants.html {
    redirect_to contracts_company_url( :id => @contract.client)
  }
  
  update.before {
    params[:contract][:building_ids] ||= nil
  }
  update.success.wants.html {
    redirect_to contracts_company_url( :id => @contract.client)
  }
  
  new_action.before {
    client = Company.find(params[:client_id])
    @contract.client = client
  }
  def projects
    load_object
  end
  
  def auto_complete_for_building_name
    @buildings = Building.find(:all, :conditions => ["LOWER(name) LIKE ?", "%#{params[:building][:name].downcase}%"], :limit => 10)
    render :partial => "auto_complete_for_building_name", :layout => false
  end
  
  def on_auto_complete_building_name
    #load_object
    @building = Building.find(params[:building_id])
    
      render :update do |page|
        page['building_name'].value = ''
        if @building.contract
          page.alert "#{@building.name} a déjà un contrat associé: #{@building.contract.name}"
        else
          page.insert_html( :top, "contract_buildings", render( :partial => 'contract_building', :locals => {:building => @building, :checked => true}) )
          page.visual_effect( :highlight, "contract_buildings")
        end
      end
  end
  
end
