class PartySweeper < ActionController::Caching::Sweeper
  
  observe Party
  
  def after_save(record)
    #list = record.is_a?(Party) ? record : record.list
    ids = record.relationships.collect(&:third_party_id)
    ids << record.id
    
    ids.each {|i| expire_fragment("parties/#{i}/*") }
  end
end