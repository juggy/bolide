class HolidaysController < ApplicationController
  require_permission 'admin'
  
  def index
    @holidays = Holiday.find(:all, :conditions => ["date >= ?", Date.today.beginning_of_month], :order => :date)
  end

  def create
    Holiday.range_create(params[:holiday])
    redirect_to holidays_url
  end
  
  def destroy
    holiday = Holiday.find(params[:id])
    holiday.destroy
    redirect_to holidays_url
  end
end
