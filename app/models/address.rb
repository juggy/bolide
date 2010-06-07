# == Schema Information
# Schema version: 20090408154321
#
# Table name: addresses
#
#  id       :integer(4)      not null, primary key
#  party_id :integer(4)      
#  location :string(255)     
#  street   :text            
#  city     :string(255)     
#  state    :string(255)     
#  zip      :string(255)     
#  country  :string(255)     
#

# require 'gettext/rails'

class Address < ScopedByAccount
  
  strip_attributes!
  
  acts_as_audited
  
  DEFAULT_STATE = 'QC'
  DEFAULT_COUNTRY = 'Canada'
  belongs_to :party
  
  def before_save
    self.zip = self.zip.gsub(" ","") if self.zip
  end
  #validates_presence_of :party
  def after_initialize
    if new_record?
      self.state = DEFAULT_STATE
      self.country = DEFAULT_COUNTRY
    end
  end
  
  def zip
    z = read_attribute(:zip)
    z && z.size > 5 ? z.gsub(" ","").insert(3, " ") : z
  end
  
  def to_s
    lines = []
    lines << line1
    lines << line2
    lines << self.country unless self.country.blank?
    lines.compact.join("\n")
  end
  
  def line1
    self.street unless self.street.blank?
  end
  
  def line2
    [
      [ (self.city unless self.city.blank?),
       (self.state unless self.state.blank?)
      ].compact.join(", ") ,
      (self.zip unless self.zip.blank?)
    ].compact.join(" ")
  end
  
  def map_url
    address = []
    address << self.street unless self.street.blank?
    address << "#{self.city}," unless self.city.blank?
    address << self.state unless self.state.blank?
    address << self.zip unless self.zip.blank?
    address << self.country unless self.country.blank?
    "http://maps.google.com/maps?q=#{address.join(" ")}"
  end
  
  def to_duplicate_sphinx_search_term
    terms = []
    terms.concat self.street.gsub("\n", " ").split(" ") unless self.street.blank?
    terms.concat self.city.split(" ") unless self.city.blank?
    terms.concat self.zip.gsub(" ", "").split(" ") unless self.zip.blank?
    
    self.class.build_sphinx_fuzzy_search( terms )
  end
  
  # You need to use :match_mode => :extended2 for this to work
  def self.build_sphinx_fuzzy_search( terms )
    terms = terms.split(" ") if terms.is_a?(String)
    return "" if terms.blank?
    
    # keep only words longer than 2 caracters, but exclude numbers
    # ex: rue de la => rue
    # ex: 50 de laval => 50 laval
    s = terms.reject {|term| term.size <= 2 && term.to_i == 0 }
    
    # each term gets starred to match word variations, ex: lava* will match laval
    # and we do a quorum search: ("one two three four"/3) needs to match at least 3 of these 4 words
    num = s.size - 1
    starred_terms = s.collect {|t| "#{t}*"}.join(" ")
    %Q{"#{starred_terms}"/#{num}}
  end
end
