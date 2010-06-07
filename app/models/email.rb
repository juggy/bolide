# == Schema Information
# Schema version: 20090408154321
#
# Table name: contact_data
#
#  id       :integer(4)      not null, primary key
#  party_id :integer(4)      
#  type     :string(255)     
#  name     :string(255)     
#  value    :string(255)     
#

class Email < ContactDatum
  
  # From restful authentication
  cattr_accessor :email_name_regex, :domain_head_regex, :domain_tld_regex, :email_regex
  self.email_name_regex  = '[\w\.%\+\-]+'.freeze
  self.domain_head_regex = '(?:[A-Z0-9\-]+\.)+'.freeze
  self.domain_tld_regex  = '(?:com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum|[A-Z]{2})'.freeze
  self.email_regex       = /\A#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}\z/i
  
  named_scope :own, :conditions => "(name <> 'cc' or name is null)"
  
  def to_s
    "#{party_name} <#{self.value}>"
  end
  
  def self.find_party_id(email, name = "")
    e = self.own.find_all_by_value(email)
    if e.size > 1
      name = normalize_name(name)
      selected = e.detect {|email| email.party_name == name }
      selected ? selected.party_id : e[0].party_id
    elsif e.size == 1
      e[0].party_id
    else
      nil
    end
  end
  
  def self.find_internal_ccs(email)
    self.find_all_by_value(email, :conditions => "name = 'cc'")
  end
  
  def party_name
    Email.normalize_name(party.name)
  end
  
  def self.normalize_name(name)
    name.gsub(".","")
  end
  
  # This is a bit of an abuse placing it here
  def self.parse(email)
    # Two rescue level
    # First might crash when accents in name
    # second drops the name and can only crash if email address is totally invalid
    begin
      begin
        email = TMail::Address.parse(email.to_s) unless email.is_a?(TMail::Address)
        # email,     name
        return [email.spec, TMail::Unquoter.unquote_and_convert_to(email.phrase, 'utf-8')]
      rescue
        email =  TMail::Address.parse(email.to_s.match(/<(.*)>/)[1])
        return [email.spec, TMail::Unquoter.unquote_and_convert_to(email.phrase, 'utf-8')]
      end
    rescue
      [nil,nil]
    end
  end
end
