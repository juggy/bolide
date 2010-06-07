class AddressesController < ApplicationController
  def destroy
    @address = Address.find(params[:id])
    @address.destroy

    respond_to do |format|
      format.js { render( :update ) {|page| page.remove "#{dom_id @address}" } }
#      format.html { redirect_to _url }
    end   
  end
end