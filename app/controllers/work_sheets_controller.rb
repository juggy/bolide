class WorkSheetsController < ApplicationController
  require_permission 'destroy_work_sheets', :only => [:destroy]

  before_filter :get_project
  helper_method :inside_global_work_sheet_list?
  
  def select_state
    render :inline => 
      "<%= select_tag 'work_sheet[state]', options_for_select( WorkSheet.state_select_options('#{params[:department]}')) %> 
      <%= javascript_tag(\"replace_default_description('#{params[:department]}')\") %>",
        :layout => false
  end
  
  def index
    restore_session_params("work_sheets_filter", :defaults => { :work_sheet_state_id => 'new', :department => 'service'} )

    @work_sheets = !inside_global_work_sheet_list? ? @project.work_sheets :
          (@work_sheets_scope =
            WorkSheet.for_manager(params[:manager_id]).
                    for_project_manager(params[:project_manager_id]).
                    for_foreman(params[:foreman_id]).
                    end_min_date(params[:end_min_date]).
                    end_max_date(params[:end_max_date]).
                    invoice_min_date(params[:min_date]).
                    invoice_max_date(params[:max_date]).
                    for_state(params[:work_sheet_state_id]).
                    for_department(params[:department_id])
                    ).
              paginate( :per_page => 100, :page => params[:page])
                    
  end

  def show
    @work_sheet = @project.work_sheets.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.pdf { send_data WorkSheetPdf::generate(@work_sheet.interventions.build), :filename => "bon_de_travail_#{@work_sheet.id}.pdf" }
    end
  end
  
  def new
    if params[:duplicate_id]
      to_dup = WorkSheet.find(params[:duplicate_id])
      @work_sheet = to_dup.duplicate
    else    
      @work_sheet = @project.work_sheets.build
      @work_sheet.use_project_defaults
    end
  end
  
  def edit
    @work_sheet = @project.work_sheets.find(params[:id])
  end
  
  def create
    @work_sheet = @project.work_sheets.build(params[:work_sheet])
  
    if @work_sheet.save
      flash[:notice] = 'WorkSheet was successfully created.'
      redirect_to(project_work_sheet_url(@project, @work_sheet))
    else
      render :action => "new"
    end

  end
  
  def update
    @work_sheet = @project.work_sheets.find(params[:id])
  
    if @work_sheet.update_attributes(params[:work_sheet])
      flash[:notice] = 'WorkSheet was successfully updated.'
      redirect_to(project_work_sheet_url(@project, @work_sheet))
    else
      render :action => "edit"
    end
    
  end
  
  def destroy
    @work_sheet = @project.work_sheets.find(params[:id])
    @work_sheet.destroy
  
    redirect_to(work_sheets_url)
  end
  
  def auto_complete_for_user_name
    @users = Role.find_by_name('couvreur').users.active.find(:all, :conditions => ["LOWER(CONCAT(first_name, ' ', last_name)) LIKE ?", "%#{params[:user][:name].downcase}%"], :limit => 10)
    # render :inline => "<%= auto_complete_result(@users, 'full_name') %>"
    render :partial => "auto_complete_for_user_name", :layout => false
  end
  
  def report
    restore_session_params("work_sheets_filter", :defaults => { :work_sheet_state_id => 'new'} )
    
    @work_sheets = @project ? @project.work_sheets :    
          WorkSheet.for_manager(params[:manager_id]).
                    for_project_manager(params[:project_manager_id]).
                    for_foreman(params[:foreman_id]).
                    invoice_min_date(params[:min_date]).
                    invoice_max_date(params[:max_date]).
                    for_state(params[:work_sheet_state_id])
                    
    
    
    respond_to do |format|
      #format.html { redirect_to :action => 'index'}
      format.html do
        render :layout => 'report'
      end
      format.csv do
        csv_string = WorkSheet.report_csv(@work_sheets, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=statistique_bon_de_travail.csv"
      end
    end
  end
  
  protected
    def get_project
      @project = params[:project_id] ? Project.find(params[:project_id]) : nil
    end
    
    def inside_global_work_sheet_list?
      !@project
    end
end
