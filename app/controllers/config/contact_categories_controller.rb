class Config::ContactCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégories de contact")
end
