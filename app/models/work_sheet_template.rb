class WorkSheetTemplate < ScopedByAccount
  validates_presence_of :title, :message => "Il faut un titre"
  # validates_inclusion_of :department, :in => WorkSheet::DEPARTMENTS, :allow_blank => true
  validates_uniqueness_of :department_id, :scope => :account_id, :allow_blank => true, :message => "Un autre gabarit est déjà associé par défaut à ce département"
end
