class LinkedMessagesController < ApplicationController

  PARTIES = [Party.to_s, Contact.to_s, Company.to_s, Building.to_s]
  # get the list for a specific party/object
  def index
    type = params[:type]
    id = params[:id]
    @f = params[:filter]
    
    if !@f.nil? && !@f.empty?
      @messages = filter(@f)
    end
    
    if(PARTIES.include? type)
      party = Party.find(id)
      @lm = linked_messages_for_party(party)
      # unless @messages
      #         relations = Relationship.employer.find(:all, :conditions=>{:first_party_id=>party.id})
      #         parties = relations.collect{|r| r.third_party }
      #         parties << party
      #       
      #         #find other recipients based on emails
      #         @messages = messages_for_parties(parties) 
      #       end
    
    elsif type == Project.to_s
      project = Project.find(id)
      @lm = linked_messages_for_party(project)
      # @messages = messages_for_parties(project.involved_parties) unless @messages
    end
    
    #get the last 10 messages forwarded by the current_user
    @messages = lastest_forwards(@lm) unless @messages
    
      
    if @lm
      @messages = @messages.select {|m| !@lm.include?(m)}
    end
    
    render :partial=>"/linked_messages/index"
  end
  
  def create
    type = params[:type]
    id = params[:id]
    lm_ids = params[:ids]
    
    if(PARTIES.include? type)
      party = Party.find(id)
      if lm_ids
        lm_ids.each_key do |m_id|
          party.linked_messages.create(:party_id=>party.id, :message_id=>m_id, :user_id=>User.current_user.id)
        end
      end
      redirect_to party
    elsif type == Project.to_s
      project = Project.find(id)
      if lm_ids
        lm_ids.each_key do |m_id|
          project.linked_messages.create(:project_id=>project.id, :message_id=>m_id, :user_id=>User.current_user.id)
        end
      end
      redirect_to project
    end
  end
  
protected

  def lastest_forwards(prev_linked)
    conditions = ["author_id = (?)", current_user.id]
    if(prev_linked && !prev_linked.empty?)
      conditions[0] = conditions[0] + " AND id not in (?)"
      conditions << prev_linked.collect{|m| m.id}
    end
    Message.find(:all, 
                :conditions=>conditions,
                :order=>"created_at DESC", 
                :limit=>10)
  end

  def filter(f)
    Message.search "*" + f + "*", 
                    :with => {:account_id => Account.current_account.id},
                    :match_mode => :extended,
                    :order => "created_at DESC, @relevance DESC",
                    :sort_mode =>:extended,
                    :field_weights => {
                      :subject => 3, #more weight on the subject
                      :body => 1,
                      :text_body => 1
                    }
  end

  def linked_messages_for_party(party)
    party.linked_messages.collect do |lm|
      lm.message
    end
  end
  
  def messages_for_parties(parties)
    messages = parties.collect do |p|
      messages_for_party(p)
    end
    messages.flatten!
  end

  def messages_for_party(party)
    emails = Email.find(:all, :conditions=>["party_id = ?", party.id]).collect{ |email| email.value }        
    Message.find(:all, :joins=>:message_recipients, :conditions=>{:private=>false, :message_recipients=>{:email => emails}})
  end
  
end