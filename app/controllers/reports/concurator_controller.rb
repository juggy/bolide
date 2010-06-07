class Reports::ConcuratorController < ApplicationController
  require_permission 'show_concurator'
  
  layout 'fullscreen'
  
  def show
    params[:min_date] ||= Time.now.beginning_of_month.strftime('%Y-%m-%d')
    params[:max_date] ||= Time.now.end_of_month.strftime('%Y-%m-%d')
    
    @bids = Bidder.find(:all, :include => :project, 
      :conditions => {:won => true, :projects => {:close_quote_by => (params[:min_date]..params[:max_date])} } )
    
    @competitors = @bids.group_by {|b| b.company}
  end
  
  def won
    params[:min_date] ||= Time.now.beginning_of_month.strftime('%Y-%m-%d')
    params[:max_date] ||= Time.now.end_of_month.strftime('%Y-%m-%d')
    
    @projects = Project.all(:conditions => ["bid_position = 1 and close_quote_by between ? and ?", params[:min_date], params[:max_date]], :include => :bidders)
    
  end
  
end