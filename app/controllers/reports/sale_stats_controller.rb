class Reports::SaleStatsController < ApplicationController
  # require_permission 'show_complete_reports'
  
  layout 'fullscreen'
  helper_method :stats_group
  
  def show
    params[:group] = if !params[:group].blank? && stats_group.flatten.include?(params[:group])
        params[:group]
      else
        'estimator'
      end
    params[:min_start_date] ||= Time.now.beginning_of_year.strftime('%Y-%m-%d')
    params[:max_start_date] ||= Time.now.end_of_year.strftime('%Y-%m-%d')
    @stats = Project.min_creation_date(params[:min_start_date]).
                     max_creation_date(params[:max_start_date]).
                     all( :include => [params[:group]])
    
    amounts = ActiveRecord::Base.connection.select_all("select w.project_id, sum(i.invoice_amount) as amount from work_sheets w inner join invoices i on i.work_sheet_id = w.id group by w.project_id")
    @invoiced_amounts = amounts.index_by {|a| a["project_id"].to_i}
    
    @grouped_stats = @stats.group_by {|p| p.send(params[:group])}
    
    if !current_user.has_permission?('show_complete_reports')
      @grouped_stats = {current_user => (@grouped_stats[current_user] || [])  }
    end
    
    @stats_summary = {}
    @stats_total = Hash.new(0)
    @grouped_stats.each do |group, stats|
      stat = {
        :calls => stats.size,
        :quotes => stats.select {|proj| proj.was_quoted? }.size,
        :service => stats.select {|proj| !proj.was_quoted? && proj.service? }.size,
        :won => stats.select {|proj| proj.was_won? }.size,
        :amount_won => stats.sum {|proj| proj.was_won? ? proj.quoted_amount.to_f : 0.0 },
      }
      stat[:amount_service] = stats.sum do |proj| 
        if !proj.was_quoted? && proj.service?
          (@invoiced_amounts[proj.id] || {})["amount"].to_f
        else
          0.0
        end
      end
      @stats_summary[group] = stat
      [:calls, :quotes, :won, :amount_won, :service, :amount_service].each {|field| @stats_total[field] += stat[field] }
    end
  end
  
protected

  def stats_group
    [ ['Estimateur','estimator'],
      ['Gestionnaire','manager'],
      ['Technologie','technology'], 
      ['Type de travaux','work_type'],
      ["Type d'immeuble", "building_type"],
      ["Source", "source"]
    ]
  end
  
end