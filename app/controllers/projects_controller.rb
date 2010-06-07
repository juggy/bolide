require 'iconv'
class ProjectsController < ApplicationController

  before_filter :set_context
  
  require_permission 'create_calls', :only => [:new, :create, :destroy]
  
  def auto_complete_for_project_no
    @projects = Project.auto_complete_search(params[:project_no_search])
    render :partial => 'auto_complete_for_project_no'
  end

  def index
    current_collection = validate_collection_params
    
    restore_from_session_or_default_filters(current_collection)
    
    @search = Project.send(current_collection).searchlogic( params[:search] )
    
    if current_collection == 'quote_in_progress'
      @late_quote_count = @search.count(:conditions => ["close_quote_by <= ?", Time.now]) 
      @quote_count = @search.count
    elsif current_collection == 'prospect'
      @total_quoted_roofer_time = @search.sum(:quoted_roofer_time)
      @total_quoted_amount = @search.sum(:quoted_amount)
    end
    
    @projects = (current_collection == 'closed') ?
          @search.paginate(:page => params[:page], :per_page => 25) :
          @search.paginate(:page => params[:page], :per_page => 25, :include => [{:building => :contract_type}, :estimator, :manager, :documenter, :prospect_status])
    
    render :action => 'index'
  end
  
  def select
    project = Project.find(params[:id])
    session[:project_id] = project.id
    party = project.client
    party ||= project.building
    party ||= project.call.contact if project.call
    if party
      redirect_to party
    else
      redirect_to :controller => 'search'
    end
  end

  def deselect
    project_id = session[:project_id]
    session[:project_id] = nil
    redirect_to project_url(project_id)
  end
  
  def show
    @project = Project.find(params[:id])
  end

  def history
    restore_session_params("project_history_filter", :defaults => {:user_id => current_user.id})
    @project = Project.find(params[:id])
    @history = @project.activities.history.by_type(params[:activity_type]).by_user(params[:user_id]).by_category(params[:category_id])
  end
  
  def new
    if params[:client_id]
      @project = Company.find(params[:client_id]).projects.build
    else
      @project = Project.new
    end
  end

  def edit
    @project = Project.find(params[:id])
    @project.client_id = params[:client_id] if params[:client_id]
  end

  def create
    @project = Project.new(params[:project])

    respond_to do |format|
      if @project.save
        flash[:notice] = 'Project was successfully created.'
        format.html { redirect_to project_url(@project) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      (params[:project] ||= {} )[:warranty_info_attributes] ||= {}
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to project_url(@project) }
        format.js { @current_project = @project}
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    redirect_to projects_url
  end
  
  # Non rest
  
  def duplicate
    @project = Project.find(params[:id])
    dup = Project.find(params[:duplicate_id])
    if @project.close_duplicate!(dup)
      redirect_to project_url(@project)
    end
  end

  def not_duplicate
    @project = Project.find(params[:id])
    if @project.remove_duplicate_flag!(@project)
      redirect_to project_url(@project)
    end
  end
  
  # PDF
  # RECQ
  def recq
    @project = Project.find(params[:id])
    respond_to do |wants|
      wants.pdf { send_data RecqSheetPdf::generate(@project), :filename => "formulaire_recq_#{@project.contract_number || @project.id }.pdf" }
    end
  end
  
  def project_followup
    @project = Project.find(params[:id])
    
    respond_to do |wants|
      wants.pdf { send_data ProjectFollowupSheetPdf::generate(@project), :filename => "suivi_contrat_#{@project.call_number}.pdf" }
    end
  end
  
  # Reports
  def quote_in_progress_list
     @projects = get_projects(:quote_in_progress, 'close_quote_by asc')
     render :partial => 'quote_in_progress_full_list', :layout => 'report', :locals => {:projects => @projects}
  end
  
  def prospect_list
     @projects = get_projects(:prospect, 'quote_number asc')
     render :partial => 'prospect_full_list', :layout => 'report', :locals => {:projects => @projects}
  end
  
  def active_list
    respond_to do |format|
      format.html { redirect_to :action => 'index'}
      format.csv do
        @projects = get_projects(:active, 'contract_number')
        csv_string = Project.active_list_to_csv(@projects, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=liste_des_projets_en_cours.csv"
      end
    end
  end
  
  protected

  def set_context
    @context = "Project"
  end
  
  def get_projects(collection, order = 'close_quote_by asc')
    @projects = Project.send( collection ).for_estimator( params[:estimator_id] ).for_manager( params[:manager_id] ).for_state( params[:state] ).for_prospect_status( params["prospect_status_id"] ).find( :all, :order => order )
  end
  
  def validate_collection_params
    current_collection = ''
    if params[:collection] == 'call'
      current_collection = 'call'
    else
      current_collection = params[:collection] || session["last_project_collection"] || 'quote_in_progress'
      current_collection = 'quote_in_progress' unless ['call', 'quote_in_progress', 'prospect', 'active', 'closed'].include?( current_collection )
      session["last_project_collection"] = params[:collection] = current_collection
    end
    current_collection
  end
  
  def restore_from_session_or_default_filters( current_collection )
    session_search_key = "#{current_collection}_project_filter"
    restore_search_from_session_or_default( session_search_key ) do 
      {
          :call               => { :order => "ascend_by_call_number"},
          :quote_in_progress  => { :order => 'ascend_by_close_quote_by'},
          :prospect           => { :order => 'ascend_by_quote_number'},
          :active             => { :order => 'ascend_by_contract_number',  :state => "production" },
          :closed             => { :order => 'descend_by_contract_number', :state => "finished" }
      }[current_collection.to_sym].merge( default_filter_user_role_params )
    end
  end
  
end
