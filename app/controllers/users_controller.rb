class UsersController < ApplicationController
  before_filter :require_admin_or_hr
  
  def index
    params[:search] ||= {:system_user => true}
    @search = User.ascend_by_name.searchlogic( params[:search] )
    @users = @search.paginate(:page => params[:page], :per_page => 20)
  end

  def new
    @roles = Role.find(:all, :order => 'name')
    @user = User.new
  end

  def create
    @roles = Role.find(:all, :order => 'name')
    @user = User.new(params[:user])
    check_protected_fields
    if @user.save
      @user.set_roles((params[:roles] || {}).keys)
      @user.set_permissions((params[:permissions] || {}).keys) if current_user.has_permission?('admin')
      flash[:notice] = _("Usager créé")
      redirect_to( :action => 'index' )
    else
      render :action => 'new'
    end
  end

  def edit
    @roles = Role.find(:all)
    @user = User.find(params[:id])
  end

  def update
    @roles = Role.find(:all)
    @user = User.find(params[:id])
    
    check_protected_fields
    
    if @user.update_attributes(params[:user])
      @user.set_roles((params[:roles] || {}).keys)
      @user.set_permissions((params[:permissions] || {}).keys) if current_user.has_permission?('admin')
      flash[:notice] = _("Usager modifié")
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end
  
  protected
  
  def check_protected_fields
    params[:user].delete(:system_user) if @user.access_level > current_user.access_level
    params[:user].delete(:access_level) if @user.access_level > current_user.access_level
  end
  
  def require_admin_or_hr
    unless current_user.can_create_users?
      permission_denied
    end
  end
  
end
