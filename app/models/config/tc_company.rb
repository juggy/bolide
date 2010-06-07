class TcCompany < ScopedByAccount
  set_table_name :config_tc_companies
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  def to_s; name;end
  
  def pdf_name
    name.upcase.gsub(/\(\d\)/, "")
  end
end