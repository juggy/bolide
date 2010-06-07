module AuditHelper
  
  def class_name(object)
    case object
    when Contact
      _("Contact")
    when Company
      _("Compagnie")
    when Building
      _("Immeuble")
    when Task
      _("Tâche")
    when Note
      _("Note")
    when Address
      _("Adresse")
    when PhoneNumber
      _("Téléphone")
    when Email
      _("Courriel")
    when Website
      _("Site web")
    when OtherContactDatum
      _("Autres")
    when WorkSheet
      _("Bon de travail")
    else
      object.class.to_s
    end
  end
  
  def audit_action_name(audit)
    suffix = ( audit.revision.is_a?(Party) || audit.revision.is_a?(Project) ) ? "" : class_name( audit.revision )
    ( audit.action == 'create' ? _("création") : _("modification") ) + " " + suffix
  end
  
  def humanize_audit(audit)
    r = []
    #audit.changes.collect {|f,v| "#{f.to_assoc.humanize}: #{audit.revision.send(f.to_assoc).to_s}"}
    audit.changes.each do |field, val|
      method_name = field.to_assoc
      object = audit.revision
      label = I18n.t "audits.#{method_name}"
      
      value = object.send("localized_#{method_name}") if object.respond_to?("localized_#{method_name}")
      value ||= object.send(method_name) if object.respond_to?(method_name)
      
      display_value = case value
      when DateTime, Date, Time
        value.localize(:short)
      else
        value.to_s
      end
      
      r << [label, display_value]
    end
    r
  end
  
end