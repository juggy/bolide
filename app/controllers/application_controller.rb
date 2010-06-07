# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
# require 'gettext/rails'

class ApplicationController < ActionController::Base
  filter_parameter_logging :password
  helper :all

  include AccountLocation
  include AuthenticatedSystem
  include PermissionSystem
  
  def test_exception
    raise "TEST Exception"
  end
  before_filter :load_current_account
  
  before_filter :require_user
  
  helper_method :current_account, :current_user_session, :current_user, :logged_in?

  before_filter { |c| User.current_user = nil; User.current_user = c.send(:current_user) }
  before_filter { |c| CurrentRequestCache.clear } # reset the cache for this new request
  
  helper_method :unread_messages
  helper_method :email_user
  
  before_filter :set_current_project
  
  audit Project, Party, Address, ContactDatum, WorkSheet
  
  def unread_messages
    count_unread = Message.unread(current_user.id).length
    @unread_messages =  count_unread > 0 ? "<b>(#{count_unread})</b> " : ""
  end
  
  def self.simple_config(name = "")

      define_method :set_title do
        @config_title = name
      end

  end
  
  protected
    #after_filter  :unset_current_account

    def load_current_account
      Account.current_account = nil # clear previous
      
      @current_account ||= Account.find_by_subdomain(account_subdomain)
      unless @current_account
        unless @no_account_redirect
          redirect_to "http://ccubeapp.com/?invalid_account=#{account_subdomain}"
        else
          raise ScopedByAccount::MissingAccountError
        end
      end
         
      Account.current_account = @current_account
      # Thread.current[:current_account] = 1
    end
    
    def current_account
      @current_account
    end
    
    # Messaging module, all controllers use this method when overriding the current mailbox
    def email_user
      if !params[:email_user_id].blank?
        session[:email_user_id] = params[:email_user_id]
      end
      
      @email_user ||= 
        if !session[:email_user_id].blank? && current_user.has_permission?('show_other_user_emails')
          User.active.find(session[:email_user_id])
        else
          current_user
        end
    end
    
    def set_current_project
      @current_project = Project.find(session[:project_id]) if session[:project_id]
    end
    
    def restore_session_params(saved_params_name, options = {})
      current_params = params.except("controller","action", "id", "_method", "format", "page")
      session_params = session[saved_params_name] || HashWithIndifferentAccess.new(options[:defaults])
      merged_params = session_params.merge(current_params)
      session[saved_params_name] = merged_params
      params.merge!(merged_params)
    end
    
    def restore_search_from_session_or_default( session_search_key, defaults = {} )
      if params[:search].nil?
        # restore from session
        if session[session_search_key].present?
          params[:search] = session[session_search_key]
        else
          # or default values
          params[:search] = block_given? ? yield : defaults
        end
      else
        session[session_search_key] = params[:search]
      end
    end
    
    def default_filter_user_role_params

      Dashboard.search_options_for(current_user)
    end
    
    def replace_UTF8(field)
      charset = machine_is_mac? ? 'MacRoman//IGNORE//TRANSLIT' : 'ISO-8859-15//IGNORE//TRANSLIT'
      ic_ignore = Iconv.new(charset, 'UTF-8')
      field = ic_ignore.iconv(field)
      ic_ignore.close

      field
    end

    def machine_is_mac?
      request.env['HTTP_USER_AGENT'].to_s.downcase.include?( 'mac'  )
    end
    
    
    def set_full_layout
      @cg_full_page_layout = true
    end

end
