class Reports::ContractStatsController < ApplicationController
  # require_permission 'show_complete_reports'

  layout 'fullscreen'
  helper_method :stats_group, :stats_status
  
  def show
    set_stats_group
    set_stats_status
    params[:min_start_date] ||= Time.now.beginning_of_year.strftime('%Y-%m-%d')
    params[:max_start_date] ||= Time.now.end_of_year.strftime('%Y-%m-%d')
    
    @stats = ContractSummary.for_states(params[:states]).
             min_work_end_date(params[:min_start_date]).
             max_work_end_date(params[:max_start_date]).
             find(:all, :include => :project, :conditions => ["projects.service = ?", false])
            
    @grouped_stats = @stats.group_by {|p| p.send(params[:group])}
    
    if !current_user.has_permission?('show_complete_reports')
      @grouped_stats = {current_user => (@grouped_stats[current_user] || [])  }
    end
    
    respond_to do |format|
      format.html do
        render :action => 'show'
      end
      format.csv do
        csv_string = ContractSummary.report_contract_stats_csv(@stats, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=statistiques_contrats_#{params[:min_start_date]}--#{params[:max_start_date]}.csv"
      end
    end
  end
  
protected

  def stats_status
    [ [Project.states_name["finished"], "finished"], 
      [Project.states_name["contract_end_docs"], "contract_end_docs"], 
      [Project.states_name["final_verification"], "final_verification"],
      [Project.states_name["production"], "production"]
    ]
  end
  
  def stats_group
    [ ['Estimateur','estimator'],
      ['Gestionnaire','manager'],
      ['Directeur de projet','project_director'],
      ['Chargé de projet','project_manager'],
      ["Chef d'équipe", 'foreman'],
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
        'estimator'
      end
  end
  
  def set_stats_status
    params[:states] ||= ["finished"]
    params[:states].reject! {|st| !stats_status.flatten.include?(st) }
  end
end