class WorkSheetTemplatesController < ResourceController::Base
  
  create.success.wants.html { redirect_to collection_path }
  update.success.wants.html { redirect_to collection_path }
  
end
