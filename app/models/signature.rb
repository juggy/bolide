class Signature
  
  def initialize(user)
    @user = user
  end
  
  def render
    suffix = @user.suffix.present? ? ",&nbsp;#{@user.suffix}" : ""
    phone = default_style("", @user.phone)
    cell = default_style("cell: ", @user.cell)
    title = default_style("", @user.job_title, true)
%(
<table border="0" cellpadding="5" cellspacing="0">
  <tbody>
    <tr valign="top">
      <td colspan="2" height="40">
        <span style="font-family: Arial,Helvetica,sans-serif; font-size: 12px; font-weight: bold; color: rgb(0, 0, 0);">#{@user.first_name}&nbsp;#{@user.last_name}#{suffix}</span><br>
        #{title}
        <a style="font-family: Arial,Helvetica,sans-serif; font-size: 12px; color: rgb(0, 0, 0);" href="mailto:#{@user.email}">#{@user.email}</a><br>
        #{phone}
        #{cell}
      </td>
    </tr>
    <tr>
      <td valign="top" width="70">
        <a href="http://www.toit-couture.qc.ca"><img src="http://www.codegenome.com/com/tc-logo.png" alt="Toitures Couture" align="top" border="0" height="62" width="60"></a>
      </td>
      <td valign="top" width="150">
        <span style="font-family: Arial,Helvetica,sans-serif; font-size: 12px; color: rgb(0, 0, 0);">
          6565 boulevard Maricourt<br>
          Saint-Hubert<br>
          (Qu&eacute;bec) J3Y 1S8<br>
          t&eacute;l&eacute;phone: (450) 678-2562<br>
          t&eacute;l&eacute;copie: (450) 678-2534
        </span><br>
        <span style="font-family: Arial,Helvetica,sans-serif; font-weight: bold; font-size: 12px; color: rgb(0, 0, 0);">www.toit-couture.qc.ca</span>
      </td>
    </tr>
  </tbody>
</table>
)

  end
  
  def default_style(label, string, bold = false)
    if string.present?
      b = bold ? " font-weight: bold; " : ""
      %(<span style="font-family: Arial,Helvetica,sans-serif; font-size: 12px;#{b}color: rgb(0, 0, 0);">#{label}#{string}</span><br>)
    end
  end
  
end