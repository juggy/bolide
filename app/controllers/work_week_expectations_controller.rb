class WorkWeekExpectationsController < ApplicationController
  require_permission 'admin'
  
  def index
    @wwes = WorkWeekExpectation.all
    @wwe = WorkWeekExpectation.new
  end
  
  def create
    @wwe = WorkWeekExpectation.new(params[:work_week_expectation])
    if @wwe.save
      redirect_to work_week_expectations_url
    else
      @wwes = WorkWeekExpectation.all
      render :action => "index"
    end
  end
  
  def destroy
    wwe = WorkWeekExpectation.find(params[:id])
    wwe.destroy
    redirect_to work_week_expectations_url
  end
  
end
