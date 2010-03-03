require 'cramp'
require 'cramp/controller'

class MsgWsController < BaseWsController

  def create
    xml = Nokogiri::XML(request.body.string)
    msgs = []
    
    xml.css('msg').each do |msg|
      #pick only the first qs element
      node_qs = msg.at_css('qs')
      select = node_qs['select']
      qs = []
      
      if(select.nil?)
        #collect all queues name
        node_qs.css('q').each do |q|
          qs << q.content
        end
      end
      #pick the first body only
      node_body = msg.at_css('body')
      
      m = Msg.new(@account)
      m.qs = qs
      m.select = select
      m.body = node_body.content unless node_body.nil?
      msgs << m
    end
    
    warnings = []
    
    msgs.each do |msg|
      msg.send_msg
      warnings = warnings + msg.warnings
    end
    
    xml = Nokogiri::XML::Builder.new do |xml|
      if !warnings.empty?
        xml.warnings do
          warnings.each do |w|
            xml.warning w
          end
        end
      end
    end
    
    render [xml.to_xml.to_s]
  end

end