class Reports::AccountingItemsController < ApplicationController
#  require_permission 'show_complete_reports'

  layout 'fullscreen'
  
  def show
    params[:financial_year] ||= 1.year.ago.strftime("%Y")
    
    @accounting_items = AccountingItem.for_year(params[:financial_year])
    
    if !current_user.has_permission?('show_complete_reports')
      @accounting_items = AccountingItem.for_year(params[:financial_year]).for_user(current_user.id)
      # @accounting_items.reject {|ai| 
        #![ai.project.estimator_id, ai.project.manager_id, ai.project.project_manager_id, ai.project.foreman_id].include?(current_user.id)
      #}
      
    end
    
    respond_to do |format|
      format.html do
        render :action => 'show'
      end
      format.csv do
        csv_string = AccountingItem.report_csv(@accounting_items, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=travaux_en_cours#{params[:financial_year]}.csv"
      end
    end
  end
   
end