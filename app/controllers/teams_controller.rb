class TeamsController < ApplicationController
  require_permission 'modify_teams', :only => [:move]
  layout 'fullscreen'
  
  def show
    @departments = Department.all
    @roofers          = User.active.with_role "couvreur"
    
    @roofers = @roofers.group_by(&:team_leader_id)
  end
  
  def move
    id = params[:id].split("_").last
    @user = User.find(id)
    @user.team_leader_id = params[:team_leader_id]
    @user.save
    
    render :update do |page|
      page.remove dom_id(@user)
      domid = @user.team_leader ? dom_id(@user.team_leader, 'foreman' ) : 'no_foreman'
      page.insert_html :bottom, domid,
                        render( :partial => 'teams/roofer', :locals => {:roofer => @user})
      
    end
  end
  
end