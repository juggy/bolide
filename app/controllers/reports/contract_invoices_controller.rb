class Reports::ContractInvoicesController < ApplicationController
  
  layout 'fullscreen'
  
  def show
    @stats = ContractSummary.for_states(['production']).
             find(:all, :include => :project, :conditions => ["projects.service = ?", false])
    
    if !current_user.has_permission?('show_complete_reports')
      @stats = @stats.reject {|s| 
       ![ s.project.estimator_id, s.project.manager_id, s.project.project_manager_id, s.project.foreman_id ].include?(current_user.id)
      }
    end

    
     respond_to do |format|
       format.html do
         render :action => 'show'
       end
       format.csv do
         csv_string = ContractSummary.report_contract_stats_csv(@stats, current_user.separator)
         send_data replace_UTF8(csv_string),
                   :type => 'text/csv; header=present',
                   :disposition => "attachment; filename=facturation_contrats.csv"
       end
     end
  end
  
end