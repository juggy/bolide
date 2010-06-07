class BiddersController < ResourceController::Base
  belongs_to :project
  
  destroy.success.wants.html { redirect_to project_calls_path(@project) }
  update.success.wants.html  { redirect_to project_calls_path(@project) }
  create.success.wants.html  { redirect_to project_calls_path(@project) }
  create.failure.wants.html do
    @show_bidder_form = true
    @call = @project.call
    render :template => 'calls/show'
  end
  
end