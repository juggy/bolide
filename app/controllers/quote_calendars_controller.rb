class QuoteCalendarsController < ApplicationController
  layout 'fullscreen'
  
  def show
    restore_search_from_session_or_default( 'quote_calendar', default_filter_user_role_params )
    @calendar = QuoteCalendar.new(params[:search], params[:week_of])
  end

end
