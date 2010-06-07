class TasksController < ApplicationController
  
  def index
    restore_session_params("task_filter", :defaults => {:user_id => current_user.id})
    if params[:collection] == 'completed'
      @tasks = Task.completed.for_user(params[:user_id]).
                              for_category(params[:activity_category_id]).
                              for_completed_date(params[:specific_date], params[:task_date]).
                              paginate(:per_page => 10, :page => params[:page])
      render :action => 'completed'
    else
      @tasks = Task.active.for_user(params[:user_id]).
                            for_category(params[:activity_category_id]).
                            calendar(params[:calendar] == "1").
                            for_date(params[:specific_date], params[:task_date]).
                            find(:all, :include => [:activity_category, :user, {:project => :estimator}])
      @categorized_task_list = Task.categorize( @tasks )
    end
  end

  def edit
    @task = Task.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'edit_js', :layout => false}
    end
  end
  # 
  
  def create
    @task = Task.new(params[:task]) #.merge(:user => current_user))
    
    respond_to do |format|
      if @task.save
        flash[:notice] = _('Task was successfully created.')
        format.js
      else
        format.js { render :action => 'failed_create' }
      end
    end
  end
  
  def complete_form
    @task = Task.find(params[:id])
    respond_to do |format|
      format.js { render :partial => 'complete_form'}
    end
  end
  
  def complete
    @task = Task.find(params[:id])
    complete_date = params[:complete_date] == 'scheduled' ? @task.scheduled_at : Time.now
    @task.complete(complete_date)
    respond_to do |format|
      format.js
    end
  end

  def update
    @task = Task.find(params[:id])

    respond_to do |format|
      if @task.update_attributes(params[:task])
        format.js
      else
        format.js { render :action => 'failed_create' }
      end
    end
  end
    
end

