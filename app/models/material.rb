class Material < ScopedByAccount
  belongs_to :category, :class_name => "MaterialCategory", :foreign_key => "category_id"
  belongs_to :unit_type
  validates_presence_of :name, :category_id
  
end
