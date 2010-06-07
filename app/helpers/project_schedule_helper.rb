module ProjectScheduleHelper
  
  def project_manager_select_options 
    @_project_manager_select_options ||= User.to_select_options({:all_label => _("Choisir un chargé")}, Role.find_by_name("chargé de projet").users.active)
  end
  def show_prevision?
    params[:grouped_by] != 'project_manager_id'
  end
  
  def work_sheet_search_auto_complete field_id
    auto_complete_field field_id, 
      { :frequency => 0.4, 
        :url => {:controller => '/project_schedule', :action => 'search'},
          :after_update_element => 
            "function(element,value)  {
               var nodes = $(value).getElementsByTagName('a');
               if(nodes.length>0) window.location = $(nodes[0]).href;
             }" 
        }
  end
end
