class ScopedByAccount < ActiveRecord::Base
  self.abstract_class = true
  
  belongs_to :account
  validates_presence_of :account_id
  
  before_validation_on_create :set_account_id
  
  class MissingAccountError < StandardError
  end
  
  def self.find(*args)
    account_id = Account.current_account_id
    raise MissingAccountError if account_id.nil?
    
    with_scope( :find => { :conditions => {:account_id => account_id } }) do
      super
    end
  end
  
  def self.count(*args)
    account_id = Account.current_account_id
    raise MissingAccountError if account_id.nil?
    
    with_scope( :find => { :conditions => {:account_id => account_id } }) do
      super
    end
  end
  
  def self.calculate(*args)
    account_id = Account.current_account_id
    raise MissingAccountError if account_id.nil?
    
    with_scope( :find => { :conditions => {:account_id => account_id } }) do
      super
    end
  end
  
  def set_account_id
    account_id = Account.current_account_id
    raise MissingAccountError if account_id.nil?
    
    self.account_id = account_id
  end
  
end