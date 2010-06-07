# == Schema Information
# Schema version: 20090408154321
#
# Table name: equipments
#
#  id                    :integer(4)      not null, primary key
#  no                    :string(30)      
#  equipment_category_id :integer(4)      
#  description           :string(255)     
#  brand                 :string(255)     
#  model                 :string(255)     
#  serial_no             :string(50)      
#  supplier              :string(255)     
#  purchased_on          :date            
#  cost                  :decimal(10, 2)  default(0.0)
#  created_at            :datetime        
#  updated_at            :datetime        
#  borrower_id           :integer(4)      
#  status_id             :integer(4)      
#  deleted_at            :datetime        
#

class Equipment < ScopedByAccount
  set_table_name :equipments
  
  #TODO: rails 2.3 default scope active
  
  DEFAULT_LOCATION = 'entrepôt'
  DEFAULT_STATUS = 'actif'
  MAINTENANCE_REQUIRED_KM = 8000
  
  cannot_be_deleted( 'description ASC' ) # order by description
  
  named_scope :active, :conditions => ["deleted_at is null"]
  
  belongs_to :borrower, :class_name => "User", :foreign_key => "borrower_id"
  belongs_to :status, :class_name => "EquipmentStatus"
  belongs_to :tc_company
  
  has_many :audits, :class_name => "EquipmentAudit", :order => 'borrowed_date DESC, id DESC'
  
  attr_accessor :borrowed_date, :borrowed_note, :annual_maintenance, :km_maintenance
  
  before_save :audit_borrowing
  before_save :perform_maintenance
  
  def perform_maintenance
    if annual_maintenance && self.last_annual_maintenance
      self.last_annual_maintenance = self.next_annual_maintenance
    end
    if km_maintenance
      self.last_km_maintenance = self.kilometrage
    end
  end
  
  def audit_borrowing
    if !new_record? && (borrower_id_changed? || status_id_changed? || kilometrage_changed? || !@borrowed_note.blank? || annual_maintenance || km_maintenance)
      self.audits.create(
        :borrower_id => self.borrower_id, 
        :status_id => self.status_id, 
        :borrowed_note => @borrowed_note, 
        :borrowed_date => @borrowed_date, 
        :annual_maintenance => annual_maintenance, 
        :km_maintenance => km_maintenance,
        :kilometrage => kilometrage
      )
    end
  end
  
  def current_location
    self.borrower ? self.borrower.full_name : DEFAULT_LOCATION
  end
  
  def status_name
    self.status ? self.status.name : DEFAULT_STATUS
  end
  
  def last_borrowed_date
    self.audits.size > 0 ? self.audits[0].borrowed_date : self.created_at
  end
  
  def due_for_annual_maintenance?
    return false unless self.next_annual_maintenance
    self.next_annual_maintenance < Time.now.to_date
  end
  
  def next_annual_maintenance
    self.last_annual_maintenance ? (self.last_annual_maintenance + 1.year).to_date : nil
  end
  
  def due_for_km_maintenance?
    return false unless self.next_km_maintenance
    self.next_km_maintenance < self.kilometrage
  end
  
  def next_km_maintenance
    self.last_km_maintenance ? (self.last_km_maintenance + MAINTENANCE_REQUIRED_KM) : nil
  end
  
  def annual_maintenance=(m)
    @annual_maintenance = (m != "0")
  end
  def km_maintenance=(m)
    @km_maintenance = (m != "0")
  end
  
  
  def self.to_csv( equipments, separator = ",")
    FasterCSV.generate(:col_sep => separator) do |csv|
      # header row
      
      csv << [
            "no",
            "description",
            "marque",
            "modèle",
            "no série", #5
            "fournisseur",
            "date d'achat",
            "coût",
            "prêté à",
            "statut", #10
            "kilometrage",
            "date dernier entretien annuel",
            "date dernier entretien 8000km",
            "propriétaire"
            ]
              
      equipments.each do |eq|
        csv << [
            eq.no,
            eq.description,
            eq.brand,
            eq.model,
            eq.serial_no, #5
            eq.supplier,
            eq.purchased_on,
            eq.cost,
            eq.borrower.to_s,
            eq.status.to_s, #10
            eq.last_annual_maintenance,
            eq.kilometrage,
            eq.last_km_maintenance,
            eq.tc_company.to_s
          ]
      end
      
    end
  end
  
  class CsvImporter
    require 'faster_csv'
    require 'iconv'
    
    def self.import(file)
      table = FasterCSV.table(file)
      ic = Iconv.new('utf-8', 'MacRoman')
      table.each do |row|
        import_row(row, ic)
      end
    end
    
    def self.import_row(row, ic)
      attrs = row.to_hash
      
      attrs.each do |k,v|
        attrs[k] = nil if v == 0 #Faster csv reads empty values as 0 ?!?
        attrs[k] = ic.iconv(v).strip if v && v.is_a?(String) #Remove extra whitespaces
        ["vendu","perdu","réparation","scrap"].each do |st|
          attrs[:status] = st if v =~ /#{st}/i
        end
      end
      
      user = find_user(attrs.delete(:user))
      attrs[:borrower_id] = user.id if user
      # puts attrs[:borrower_id]
      # puts user.to_s
      
      
      Equipment.create!(attrs)
    end
    
    def self.find_user(name)
      return nil unless name
      
      parts = name.split(".").collect(&:strip)
      last_name = parts.last
      first_name = parts.first # only first letter
      
      users = User.find_all_by_last_name(last_name)
      return users[0] if users.size == 1
      users.detect {|u| u.first_name[0] == first_name}
    end
  end
end
