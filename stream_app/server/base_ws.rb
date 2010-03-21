require 'cramp'
require 'cramp/controller'
require 'newrelic_rpm'
require 'new_relic/agent/instrumentation/controller_instrumentation'

class BaseWsController < Cramp::Controller::Action
  extend ActiveSupport::Concern
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  
  before_start :authenticate
  on_start :send_data
  
  def send_data
    if params[:id] && request.get? && respond_to?(:show)
      show
    elsif params[:id] && request.put? && respond_to?( :update)
      update
    elsif params[:id] && request.delete? && respond_to?( :destroy)
      destroy
    elsif request.post? && respond_to?( :create)
      create
    elsif request.get? && respond_to?( :index)
      index
    end
    finish
    
  end

  def authenticate  
    #check header for account and api_key 
    begin
      auth = request.env['HTTP_X_BOL_AUTHENTICATION']
      isauth = false
      if(auth)
        
        parts = auth.split(':')
        auth_key = parts[1]
        @account = BolideApi::Account.load_with( :_id => parts[0])
        
        if(@account.saved)
          
          date = request.env['HTTP_X_BOL_DATE']
          gen_auth_key_prev = 'Account:' + @account._id + '\n' + 'Api-Key:' + @account.api_key + '\n' + 'X-Bol-Date:' + date
          gen_auth_key = Digest::MD5.hexdigest(gen_auth_key_prev)
          
          if(gen_auth_key == auth_key)
            isauth = true
            yield 
          end
        end
      end
      raise "Invalid Authentication" unless isauth
    rescue Exception => exception
      p exception.backtrace.join("\n")
      xml = Nokogiri::XML::Builder.new do |xml|
        xml.error exception.message
      end
      
      halt 500, {'Content-Type' => 'text/plain'}, xml.to_xml.to_s
    end
  end

  def respond_with
    [200, {'Content-Type' => 'application/xml'}]
  end
  
  included do
    class_inheritable_accessor :show_callback, :index_callback, :destroy_callback, :update_callback, :create_callback, :instance_reader => false
    self.index_callback = nil
    self.destroy_callback = nil
    self.update_callback = nil
    self.create_callback = nil
    self.show_callback = nil
  end
  
  module ClassMethods
    def index(method)
      self.index_callback = method
    end
    
    def show(method)
      self.show_callback = method
    end

    def destroy(method)
      self.destroy_callback = method
    end

    def update(method)
      self.update_callback = method
    end
    
    def create(method)
      self.create_callback = method
    end
  end

end
