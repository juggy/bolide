module UiNavigationHelper
  
  def quote_in_progress?
    (!@project.nil? && @project.category == :quote_in_progress ) || (params[:controller] == 'projects' && params[:collection] == 'quote_in_progress')
  end
  
  def prospect?
    (!@project.nil? && @project == :prospect ) || (params[:controller] == 'projects' && params[:collection] == 'prospect')
  end
  
  def active?
    (!@project.nil? && @project == :active ) || (params[:controller] == 'projects' && params[:collection] == 'active')
  end
  
  def closed?
    (!@project.nil? && @project == :closed ) || (params[:controller] == 'projects' && params[:collection] == 'closed')
  end
  

  def calls?
    (!@project.nil? && @project.new_call? ) || ( params[:controller] == 'projects' && params[:collection] == 'call')
   end

  def projects?
    @force_project_tab_highlight ||
    (params[:controller] == 'projects' && params[:collection] != 'call' && @project.nil?) ||
    (!@project.nil? && !@project.new_call? && !@project.service?) ||
    params[:controller] == 'quote_calendar'
  end

  def home?
    false
  end

  def work_sheets?
    params[:controller] != 'project_schedule' &&
    params[:controller] != 'dashboards' &&
    !@force_project_tab_highlight && (
  
      (!@work_sheets.nil? && @project.nil?) ||
      (!@project.nil? && @project.service? ) ||
      (params[:controller] == 'interventions') ||
      (!@invoice.nil?)
    )
  end

  def schedules?
    ['project_schedule', 'service_programs', 'daily_schedules', 'teams'].include?(params[:controller])
  end

  def buildings?
    !@party.nil? && @party.is_a?(Building)
  end

  def companies?
    !@party.nil? && @party.is_a?(Company)
  end

  def contacts?
    !@party.nil? && @party.is_a?(Contact)
  end

  def equipments?
    params[:controller] == "equipments"
  end

end