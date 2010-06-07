class ProjectMeetingsController < ApplicationController
  
  def index
    params[:estimator_id] ||= 28
    
    params[:collection] = 'quote_in_progress' unless ['quote_in_progress', 'prospect', 'hot_prospect'].include?(params[:collection])
    order = 'close_quote_by asc'
    
    case params[:collection]
    when 'quote_in_progress'
      scope = Project.quote_in_progress
      params[:min_date] ||= Time.now.beginning_of_week.to_date
      params[:max_date] ||= Time.now.end_of_week.to_date
    when 'prospect'
      scope = Project.prospect
      params[:min_date] ||= 1.week.ago.beginning_of_week.to_date
      params[:max_date] ||= 1.week.ago.end_of_week.to_date
    when 'hot_prospect'
      scope = Project.prospect.scoped(:conditions => "prospect_status_id is not null")
      
    end
    
    @projects = scope.for_estimator( params[:estimator_id] ).
                        min_quote_date(params[:min_date]).
                        max_quote_date(params[:max_date]).
                        find(:all, :order => order)
    
    @layout_hide_navigation = true
    render :layout => 'fullscreen'
  end
  
  def update
    @project = Project.find(params[:id])

    unless params[:note].blank?
      @project.notes.create(:user => current_user, :body => params[:note])
    end
    
    @project.update_attributes(params[:project])
    
    render :update do |page|
      page.insert_html :top, dom_id(@project, :new_note), simple_format(params[:note])
      page << "$('#{dom_id(@project, :note_area)}').value = '';"
    end
  end
    
end