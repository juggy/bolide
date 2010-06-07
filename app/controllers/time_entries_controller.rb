class TimeEntriesController < ApplicationController
  require_permission 'admin'
  layout 'fullscreen'
  helper_method :stats_group
  
  def index
    @time_entries = current_user.time_entries.recent
    @time_entry = TimeEntry.new(:date => Date.today)
  end

  def report
    @projects = Project.all(:conditions => ["id IN (?)", Project.connection.select_values("select distinct project_id from time_entries where project_id is not null")], :include => params[:group])
    set_stats_group
    @grouped_projects = @projects.group_by {|p| p.send(params[:group])}
    @times = @projects.inject({}) {|h,p| h[p] = p.time_entries.sum(:time, :group => :category, :conditions => "category_id is not null"); h}
    @categories = TimeEntryCategory.all
  end
  
  def create
    @time_entry = current_user.time_entries.new(params[:time_entry])
    
    render :update do |page|
      if @time_entry.save
        page.insert_html :top, 'recent_time_entries', (render :partial => 'entry', :locals => {:entry => @time_entry})
        page << 'next_entry()'
      else
        page << "$('time_entry_time').focus();"
      end
    end
  end
  
  def destroy
    entry = current_user.time_entries.find(params[:id])
    entry.destroy
    
    render :update do |page|
      page.remove dom_id(entry)
    end
  end
  
  protected
  
  def stats_group
    [ 
      # ['Estimateur','estimator'],
      # ['Gestionnaire','manager'],
      # ['Chargé de projet','project_manager'],
      # ["Chef d'équipe", 'foreman'],
      ['Technologie','technology'], 
      ['Type de travaux','work_type'],
      ["Type d'immeuble", "building_type"],
      ["Source", "source"]
    ]
  end
  
  def set_stats_group
    params[:group] = if !params[:group].blank? && stats_group.flatten.include?(params[:group])
        params[:group]
      else
        'technology'
      end
  end
  
end
