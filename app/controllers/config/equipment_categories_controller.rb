class Config::EquipmentCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégories d'équipement")
end
