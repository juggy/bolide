require 'carrot'
require 'uuid'
require 'validatable'

module BolideApi
  class InvalidKeyError < Exception
  end
  class UniquenessError < Exception
  end
  
  class Base
    include Validatable
    
    attr_accessor :saved
    
    class << self      
      def load_with(attributes)
        obj = allocate
        if attributes
          attributes.each do |key,value|
            obj.send(key.to_s + '=', value)
          end
        end
        loaded_obj = MemCache.instance.get(obj.key) do
          obj.after_initialize if obj.respond_to?(:after_initialize)
          obj.saved = false
          obj
        end
      end
    end 
  
    def save(do_validate = true)
      if(!do_validate || valid?)
        new_obj = false
        if !@saved 
          @saved = true
          new_obj = true
        end
        before_create if new_obj && respond_to?(:before_create)
        before_save if respond_to?(:before_save)
        
        MemCache.instance.set(key, self)
        
        after_create if new_obj && respond_to?(:after_create)
        after_save if respond_to?(:after_save)
        
        return true
      end
      return false
    end
    
    def key
      raise InvalidKeyError
    end
    
  end
end