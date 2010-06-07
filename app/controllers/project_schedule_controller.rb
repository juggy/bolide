class ProjectScheduleController < ApplicationController
  require_permission 'update_schedule', :only => [:update]
  require_permission ['update_schedule','show_schedule'], :except => [:update]
  
  layout 'fullscreen'
  helper_method :foreman_schedule?
  
  def search
    @work_sheets = WorkSheet.for_schedule('all').auto_complete_search( params[:term] )
    render :partial => 'search_results'
  end
  
  def show
    find_users
    @work_sheets = WorkSheet.for_schedule(params[:user_id], params[:department_id], params[:grouped_by])
  end

  def update
    ws = WorkSheet.find(params[:id])
    ws.update_attributes(params[:work_sheet])
    # redirect_to :action => 'index', :grouped_by => params[:grouped_by], :user_id => params[:user_id]
    respond_to do |wants|
      wants.js do
        render :update do |page|
          page.replace_html dom_id(ws), render(:partial => 'work_sheet', :locals => {:work_sheet => ws})
          page.visual_effect :highlight, dom_id(ws, 'end_date')
        end
      end
    end
  end

  # Non rest
  def print
    find_users
    @users << nil
    
    @grouped_work_sheets = WorkSheet.for_schedule('all').group_by(&(params[:grouped_by]).to_sym)
    
    # Only keep the relevant department for non assigned work sheet
    @grouped_work_sheets[nil].reject! {|ws| ws.department.id.to_s != params[:department_id]}
    
    if @schedule_user
      @users = [@schedule_user]
    end
    
    render :layout  => 'report'
  end
  
  
  protected
    def find_users
      # params[:user_id] = 'contract' if params[:user_id].blank?
      # params[:department_id] ||= 'contract'
      @department = Department.find(params[:department_id])
      params[:grouped_by] ||= 'foreman_id'
      if foreman_schedule?
        @users = @department.foremen
      else
        @users = Role.find_by_name('chargé de projet').users.active
      end
      
      @schedule_user = User.find(params[:user_id]) unless params[:user_id].blank? || params[:user_id].to_i == 0
    end
    
    def foreman_schedule?
      params[:grouped_by] != 'project_manager_id'
    end
    
end
