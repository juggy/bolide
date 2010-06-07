class Config::EquipmentStatusesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("EquipmentStatuses")
end
