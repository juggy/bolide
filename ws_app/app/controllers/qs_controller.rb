class QsController < ApplicationController
  before_filter :non_html_request
  before_filter :authenticate
  
  def index
    @qs = @account.qs
    respond_to do |f|
      f.xml 
    end
  end
  
  def show
    p 'crisse'
    @q = BolideApi::Q.load_with(:_id=>params[:id], :account=>@account )
    respond_to do |f|
      p f
      f.xml do 
        raise 'Invalid Queue' unless @q.saved
        render :action=>'show.xml.builder'
      end
    end
  end
  
  def update
    #try to find the q first
    @q = BolideApi::Q.load_with(:_id=>params[:id], :account=>@account)
    #save will update the expire on
    if @q.save
      render :action=>'show.xml.builder'
    else
      p @q.errors.full_messages
      raise @q.errors.full_messages.join(', ')
    end
  end
  
end
