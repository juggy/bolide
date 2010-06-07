class DashboardsController < ApplicationController
  
  layout 'fullscreen'
  
  def show
    
    @dashboard = Dashboard.new(current_user)
    
    @tasks = @dashboard.tasks
    @categorized_task_list = @dashboard.categorized_task_list
  end

end
