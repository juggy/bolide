class Dashboard
  
  PARTS_ACL = {
    :estimator            => :all,
    :manager              => :all,
    :project_manager      => [:in_production],
    :estimation_assistant => [:quote_calendar],
    :documenter           => [:in_production]
  }
  
  def self.search_options_for_roles(user)
    roles = roles_for(user)
    query = roles.map {|role| "#{role}_id = #{user.id}"}.join(" OR ")
    "(#{query})"
  end
  
  def self.primary_role_for(user)
    roles_for(user).first
  end
  
  def self.search_options_for(user)
    role = primary_role_for(user)
    role ? { "#{role}_id".to_sym => user.id } : {}
  end
  
  def self.roles_for(user)
    roles = []
    roles << :estimator             if user.has_role?("estimateur")
    roles << :manager               if user.has_role?("gestionnaire de compte")
    roles << :project_manager       if user.has_role?("chargé de projet")
    roles << :estimation_assistant  if user.has_role?("responsable soumission")
    roles << :documenter            if user.has_role?("responsable documents")
    roles
  end
  
  # attr_reader :calendar, :tasks, :categorized_task_list, :work_sheets, :activities
  attr_reader :tasks, :categorized_task_list
  
  def initialize(user)
    @user = user
    @role = Dashboard.primary_role_for(user)

    @tasks = Task.active.for_user(user.id).min_date(calendar.start_date).max_date( calendar.end_date ).
                          find(:all, :include => [:activity_category, :user, {:project => :estimator}])
    @categorized_task_list = Task.categorize( @tasks )
  end
  
  def calendar
    @calendar ||= QuoteCalendar.new(user_filter)
  end
  
  def work_sheets
    @work_sheets ||= WorkSheet.to_show_in_schedule.find(:all, 
      :conditions => ["project_id in (?) AND scheduled_date < ? AND remaining_days > 0 AND foreman_id IS NOT NULL", project_ids, calendar.end_date],
      :order => :scheduled_date)
  end
  
  def activities
    @activities ||= Activity.history.find(:all, 
      :order => "updated_at DESC",
      :conditions => ["project_id in (?) AND updated_at >= ?", 
                      project_ids, 3.days.ago],
      :include => [:party, :project],
      :limit => 100
    )
  end
  
  def tasks_only?
    PARTS_ACL[@role].nil?
  end
  
  def show_tasks?
    true
  end
  
  def show_quote_calendar?
    access_to?(:quote_calendar)
  end
  
  def show_in_production?
    access_to?(:in_production)
  end
  
  def show_activities?
    access_to?(:activities)
  end
  
  protected
    def user_filter
      @user_filter ||= Dashboard.search_options_for(@user)
    end
    
    def user_roles_filter
      @user_roles_filter ||= Dashboard.search_options_for_roles(@user)
    end
    
    def project_ids
      @project_ids ||= Project.scoped(:select => "id, state", :conditions => user_roles_filter ).collect(&:id)
    end
    
    def access_to?(part)
      acl = PARTS_ACL[@role]
      return false if acl.nil?
      return true if acl == :all
      acl.include?(part)
    end
end