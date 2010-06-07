module HrsHelper
  def competence_expiry_class(competence)
    if competence.expired?
      'expired'
    elsif competence.expires_soon?
      'expires_soon'
    else
      ''
    end
  end
  
  def absence_justified_class(absence)
    if absence.justified
      "justified_absence"
    else
      "unjustified_absence"
    end
  end
end
