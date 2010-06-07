class BuildingType < ScopedByAccount
  set_table_name :config_building_types
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  def to_s; name;end
  
end