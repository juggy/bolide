class ContactDataController < ApplicationController
  def destroy
    @contact_datum = ContactDatum.find(params[:id])
    @contact_datum.destroy

    respond_to do |format|
      format.js { render( :update ) {|page| page.remove "#{dom_id @contact_datum}" } }
#      format.html { redirect_to _url }
    end   
  end
end