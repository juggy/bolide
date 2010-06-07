class ContractType < ScopedByAccount
  set_table_name :config_contract_types
  validates_presence_of :name, :message => _("Vous devez entrer un nom")
  cannot_be_deleted
  def to_s; name;end
  
  SEC_ID = 1
  SECP_ID = 2
  SECPP_ID = 3
  PEP_ID = 4
  PRIVATE_ID = 5
  PUBLIC_ID = 6
  BASE_ID = 7
  
  CSS_CLASS = {
    SEC_ID => 'sec',
    SECP_ID => 'secp',
    SECPP_ID => 'secpp',
    # PEP_ID => '',
    # PRIVATE_ID => '',
    # PUBLIC_ID => '',
  }
  
  def css_class
    CSS_CLASS[self.id]
  end
  

end