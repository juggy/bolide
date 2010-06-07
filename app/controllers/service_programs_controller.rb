class ServiceProgramsController < ApplicationController
  require_permission 'update_schedule', :except => [:index]
  require_permission ['update_schedule','show_schedule'], :only => [:index]
  
  layout 'fullscreen'
  
  def index
    params[:department] ||= 'service'
    @program = ServiceProgram.new(:department_id => params[:department_id], :start_date => params[:week_of]) #, :week_factor => 0.6
  end

  def reschedule
    id = params[:id].split("_").last
    work_sheet = WorkSheet.find(id)
    work_sheet.foreman_id = params[:foreman_id]
    work_sheet.scheduled_date = params[:date]
    work_sheet.save
    
    refresh_work_sheet(work_sheet)
  end
  
  def edit
    @work_sheet = WorkSheet.find(params[:id])
    render :layout => false
  end
  
  def update
    work_sheet = WorkSheet.find(params[:id])
    work_sheet.update_attributes(params[:work_sheet])
    
    flash[:last_work_sheet_id] = work_sheet.id
    redirect_to service_programs_url, :department_id=>work_sheet.department_id
  end
  
  protected
    def refresh_work_sheet(work_sheet)
      flash[:last_work_sheet_id] = work_sheet.id
      render :update do |page|
        page.redirect_to :action=>"index", :department_id=>work_sheet.department_id
      end
    end
    
end
