class Reports::ServiceInvoicesController < ApplicationController
  
  layout 'fullscreen'
  helper_method :stats_group
  
  def show
    set_stats_group
    params[:min_date] ||= Time.now.beginning_of_month.strftime('%Y-%m-%d')
    params[:max_date] ||= Time.now.end_of_month.strftime('%Y-%m-%d')
    params[:invoice_type] ||= 'all'
    #TODO: metre a jour suite aux changement de la logique de facturation
    #@work_sheets = WorkSheet.service.invoiced.
    @invoices = Invoice.
                    min_date(params[:min_date]).
                    max_date(params[:max_date]).
                    for_invoice_type(params[:invoice_type]).
                    find(:all, :order => 'invoice_date asc', :include => [{:work_sheet => [:project, :interventions]}, :interventions])
    
    @grouped_stats = @invoices.group_by {|p| p.send(params[:group])}
    
    if !current_user.has_permission?('show_complete_reports')
      @grouped_stats = {current_user => (@grouped_stats[current_user] || [])  }
    end
    
    
    respond_to do |format|
      format.html do
        render :action => 'show'
      end
      format.csv do
        csv_string = Invoice.report_service_invoices_csv(@invoices, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=facturation_service_#{params[:min_date]}--#{params[:max_date]}.csv"
      end
    end
  end
  
protected

  def stats_group
    [ 
      ['Gestionnaire','manager'],
      ['Chargé de projet','project_manager'],
      ['Directeur de projet','project_director'],
      ["Chef d'équipe", 'foreman'],
      ['Technologie','technology'], 
      ['Type de travaux','work_type'],
      ["Type d'immeuble", "building_type"],
      ["Type de service", "invoice_type_name"]
    ]
  end
  
  def set_stats_group
    params[:group] = if !params[:group].blank? && stats_group.flatten.include?(params[:group])
        params[:group]
      else
        'manager'
      end
  end
  
end