class CoursesController < ResourceController::Base
  
  create.success.wants.html { redirect_to courses_url }
  update.success.wants.html { redirect_to courses_url }
  
end