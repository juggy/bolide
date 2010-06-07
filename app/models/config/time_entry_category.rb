class TimeEntryCategory < ScopedByAccount
  set_table_name 'config_time_entry_categories'
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  has_many :time_entries
  def to_s
    name
  end
end