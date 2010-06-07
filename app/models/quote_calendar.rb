class QuoteCalendar
  
  attr_reader :start_date, :end_date, :search, :events
  
  def initialize( search_params, week_of = nil)
    @start_date = week_of.present? ? week_of.to_date : default_start_date
    @end_date = @start_date + 6.days
    
    @events = QuoteEvent.find( @start_date, @end_date, search_params)
    @search = Project.searchlogic(search_params)
    
  end
  
  def date_range
    @date_range ||= (@start_date..@end_date).to_a
  end
  
  protected
  
  def default_start_date
    (Date.today + 1.day).beginning_of_week - 1.day
  end
end