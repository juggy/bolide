class Account < ActiveRecord::Base
  authenticates_many :user_sessions
  
  def self.current_account
    Thread.current[:current_account]
  end
  
  def self.current_account=(account)
    Thread.current[:current_account] = account
    Thread.current[:current_account_id] = account ? account.id : nil
  end
  
  def self.current_account_id
    Thread.current[:current_account_id]
  end
  
  ReservedSubdomains = 
      %w[admin blog dev ftp mail pop pop3 imap smtp stage staging stats status www help support aide image images stylesheet stylesheets assets assets0 assets1 assets2 assets3 assets4 assets5 assets6 assets7 assets8 assets9]
      
  validates_uniqueness_of :subdomain
  validates_length_of :subdomain, :within => 6..20
  validates_exclusion_of :subdomain, :in => ReservedSubdomains
  validates_format_of :subdomain, :with => /^[a-z0-9-]+$/
  
  before_validation :downcase_subdomain

  has_many :users
  belongs_to :company
  
  # helper for iterating through all accounts
  def self.with_each
    old = self.current_account
    self.all.each do |account|
      self.current_account = account
      yield account
    end
    self.current_account = old
  end
  
  protected

    def downcase_subdomain
      self.subdomain.downcase!
    end
end