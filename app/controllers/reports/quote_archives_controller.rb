class Reports::QuoteArchivesController < ApplicationController
  
  layout 'fullscreen'
  
  def show
    params[:min_start_date] ||= Time.now.beginning_of_year.strftime('%Y-%m-%d')
    params[:max_start_date] ||= Time.now.end_of_year.strftime('%Y-%m-%d')
    params[:sort_by] ||= "quote_number"
    @projects = Project.min_creation_date(params[:min_start_date]).
                      max_creation_date(params[:max_start_date]).
                      find(:all, :conditions => ["quote_number IS NOT NULL"], :order => params[:sort_by])
  
    respond_to do |format|
      format.html do
        render :action => 'show'
      end
      format.csv do
        csv_string = Project.quote_archive_to_csv(@projects, current_user.separator)
        send_data replace_UTF8(csv_string),
                  :type => 'text/csv; header=present',
                  :disposition => "attachment; filename=soumissions_#{params[:min_start_date]}--#{params[:max_start_date]}.csv"
      end
    end
    
  end
  
end