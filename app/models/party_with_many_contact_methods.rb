# == Schema Information
# Schema version: 20090408154321
#
# Table name: parties
#
#  id                    :integer(4)      not null, primary key
#  type                  :string(255)     
#  first_name            :string(255)     
#  last_name             :string(255)     
#  title                 :string(255)     
#  name                  :string(255)     
#  created_at            :datetime        
#  updated_at            :datetime        
#  user_id               :integer(4)      
#  manager_id            :integer(4)      
#  contract_type_id      :integer(4)      
#  building_instruction  :text            
#  contract_id           :integer(4)      
#  icc_number            :integer(4)      
#  tc_company_id         :integer(4)      
#  internal_instructions :text            
#  region_id             :integer(4)      
#  building_type_id      :integer(4)      
#  technology_id         :integer(4)      
#  height                :integer(4)      
#

class PartyWithManyContactMethods < Party
  has_many :addresses, :foreign_key => 'party_id', :dependent => :destroy
  
  has_many :contact_data, :foreign_key => 'party_id', :class_name => 'ContactDatum', :dependent => :destroy
  has_many :phone_numbers, :foreign_key => 'party_id', :dependent => :destroy
  has_many :emails, :foreign_key => 'party_id', :dependent => :destroy
  has_many :websites, :foreign_key => 'party_id', :dependent => :destroy
  has_many :other_contact_data, :foreign_key => 'party_id', :class_name => 'OtherContactDatum', :dependent => :destroy
  
  def address
    addresses.first
  end
  
  def all_audits
    all = []
    all.concat self.audits
    all.concat addresses.collect {|a| a.audits} 
    all.concat contact_data.collect { |c| c.audits }
    all.flatten.reject {|a| (a.changes || {}).keys.size == 0}.sort_by(&:created_at).reverse
  end
  
  def contact_data_attrs=(attrs)
    attrs.each do |attr|
      attr['personal'] ||= "0"

      # remove leading/trailing whitespaces
      attr.each do |key, val|
        attr[key] = val.to_s.strip
      end
      
      next if attr[:value].blank? && !attr[:id]
      
      if id = attr.delete(:id)
        cd = self.contact_data.detect {|data| data.id.to_s == id.to_s }
        cd.type = attr.delete(:type)
        cd.update_attributes(attr)
      else
        attr_type = attr.delete(:type)
        cd = self.contact_data.build(attr)
        cd.type = attr_type
      end
    end
  end
  
  
  def addresses_attrs=(attrs)
    attrs.each do |attr|

      # remove leading/trailing whitespaces
      attr.each do |key, val|
        attr[key] = val.to_s.strip
      end
      
      next if attr.except("state", "country").values.all?(&:blank?) && 
              (attr["state"] == Address::DEFAULT_STATE || attr["state"].blank? ) && 
              (attr["country"] == Address::DEFAULT_COUNTRY || attr["country"].blank?)
      
      if id = attr.delete(:id)
        a = self.addresses.detect {|address| address.id.to_s == id.to_s }
        a.update_attributes(attr)
      else
        self.addresses.build(attr)
      end
    end
  end
  
  protected
  def solr_phones
    self.phone_numbers.collect {|n| n.value.gsub(/\D/,"") }.join(" ")
  end
  
  def solr_contact_data
    self.contact_data.collect {|n| 
      n.value unless n.is_a?(PhoneNumber)
    }.compact.join(" ")
  end
  
  def solr_addresses
    self.addresses.collect {|n| n.to_s }.join(" ")
  end
end
