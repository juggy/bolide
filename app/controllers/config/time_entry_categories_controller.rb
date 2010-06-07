class Config::TimeEntryCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégorie pour la feuille de route")
end
