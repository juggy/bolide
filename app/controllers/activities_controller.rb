class ActivitiesController < ApplicationController
  
  layout 'fullscreen'
  
  def index
    proj = Project.scoped(:select => "id, state", :conditions => {:manager_id => 28} ).collect(&:id)
    @activities = Activity.history.find(:all, 
      :order => "updated_at DESC",
      :conditions => ["project_id in (?) AND updated_at >= ? AND updated_at <= ?", 
                      proj, 13.days.ago, Time.now ]
    )
  end

end
