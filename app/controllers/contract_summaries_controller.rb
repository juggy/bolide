class ContractSummariesController < ApplicationController
  require_permission 'access_accounting_infos', :except => [:show]
  
  def show
    params[:display] = 'mo' unless current_user.has_permission?('access_accounting_infos')
    @project = Project.find(params[:project_id])
    @contract_summary = @project.contract_summary
  end
  
  def update
    @project = Project.find(params[:project_id])
    @contract_summary = @project.contract_summary
    @contract_summary.update_attributes(params[:contract_summary])
    redirect_to :action => 'show', :project_id => params[:project_id]
  end
  
  helper_method :show_complete?
  def show_complete?
    params[:display] != 'mo'
  end
end