class AuditsController < ApplicationController
  
  def show
    @audit = Audit.find(params[:id])
    render :layout => 'false'
  end

end
