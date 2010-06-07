module WorkSheetsHelper
  
  def possible_work_sheet_contacts_options 
    #contacts = []
    call_contact = ["#{@project.call.contact_on_site} (contact chantier de l'appel)", nil]
    involvements = @project.involvements.collect {|inv| ["#{inv.party.name} (#{inv.role})", inv.party.id] }
    building_contacts = @project.building.relationships.collect {|rel| ["#{rel.third_party.name} (Immeuble: #{rel.description})", rel.third_party.id] } rescue []
    client_contacts = @project.client.relationships.collect {|rel| ["#{rel.third_party.name} (Client: #{rel.description})", rel.third_party.id] unless rel.third_party.is_a?(Building) } rescue []
    involvements.concat(building_contacts).concat(client_contacts.compact).unshift(call_contact)
  end
  
end
