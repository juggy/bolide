module DailySchedulesHelper
  
  def schedulable_user_select_options
    @_cached_schedulable_user_select_options ||= User.schedulable.find(:all, :include => [:contact => [:employee_info => [:level]] ]).collect{ |u| [u.name_and_level, u.id]}
  end
end