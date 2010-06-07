module Config
  module ConfigController
    
    def self.included(klass)
      klass.class_eval do
        # puts klass.name
        index.wants.html { render :template => 'config/simple/index' }
        new_action.wants.html {render :template => 'config/simple/new' }
        edit.wants.html {render :template => 'config/simple/edit' }
        create.success.wants.html { redirect_to collection_path }
        create.failure.wants.html { render :template => 'config/simple/new' }
        update.success.wants.html { redirect_to collection_path }
        update.failure.wants.html { render :template => 'config/simple/edit'}

        before_filter :set_title
        require_permission 'access_configs'
        
        def collection
          @collection ||= end_of_association_chain.active
        end
      end
      
    end
    
  end
end