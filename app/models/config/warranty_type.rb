class WarrantyType < ScopedByAccount
  set_table_name :config_warranty_types
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  
  belongs_to :warranty_info
  
  def to_s;name; end
end