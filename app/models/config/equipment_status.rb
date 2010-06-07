class EquipmentStatus < ScopedByAccount
  set_table_name :config_equipment_statuses
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
end