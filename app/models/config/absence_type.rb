require 'cannot_be_deleted'
class AbsenceType < ScopedByAccount
  set_table_name :config_absence_types
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  
  belongs_to :employee, :class_name => "Contact", :foreign_key => "employee_id"
  
  def to_s; name; end
end