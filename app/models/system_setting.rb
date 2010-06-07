# == Schema Information
# Schema version: 20090408154321
#
# Table name: system_settings
#
#  id    :integer(4)      not null, primary key
#  name  :string(255)     
#  value :string(255)     
#

class SystemSetting < ScopedByAccount
  validates_uniqueness_of :name, :scope => :account_id
  
  class << self
    
    if !Rails.env.production?
      def owner_id
        Account.current_account.company_id ||@owner_id || OWNER_ID
      end
      
      if Rails.env.test?
        def owner_id=(oid)
          @owner_id = oid
        end
      end
      
    else
      def owner_id
        OWNER_ID
      end
    end
    
    def next_quote_number
      next_number("quote")
    end
    
    def next_call_number
      next_number("call")
    end
    
    def next_building_icc_number
      next_number("building_icc")
    end
    
    protected
    def next_number(name)
      SystemSetting.transaction do
        setting = self.find_or_create_by_name("next_#{name}_number")
        setting.lock!
        setting.value = setting.value.to_i + 1
        setting.save!
        setting.value
      end
    end
  end
end
