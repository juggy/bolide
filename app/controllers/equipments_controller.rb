class EquipmentsController < ResourceController::Base
  require_permission 'create_and_update_equipments', :except => [:index, :show]
  
  def index
    search_params = (params[:search] || {}).reverse_merge( { "order" => "ascend_by_no" } )
    @search = Equipment.active.searchlogic( search_params )
    @equipments = @search.paginate( :page => params[:page], :per_page => 20 )
    respond_to do |wants|
      wants.html
      wants.csv do
        # next line, strange bug with order in named scope
        csv_string = Equipment.to_csv(Equipment.all(:conditions => {:deleted_at => nil}, :order => 'no'), current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=liste_equipements_#{Date.today}.csv"
        
      end
    end
    
  end
  
  destroy.wants.html { redirect_to equipments_url }

  
  def quick_update
    @equipment = Equipment.find_by_no(params[:equipment][:no])
    if @equipment
      previous_km = @equipment.kilometrage
      @equipment.update_attributes(params[:equipment])
      render :update do |page|
        page.insert_html :top, "updated_equipments", "<div>#{@equipment.no} #{@equipment.description} #{previous_km} km => #{@equipment.kilometrage} km</div>"
        page << "$('equipment_no').value = ''; $('equipment_kilometrage').value = ''; $('equipment_no').focus();"
      end
    else
      render :update do |page|
        page.insert_html :top, "updated_equipments", "<div style='color:red'>Ne peut trouver #{params[:equipment][:no]}</div>"
      end
    end
  end
end
