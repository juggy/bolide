class Config::ProjectCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégories de projets")
end
