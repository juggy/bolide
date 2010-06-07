module BiddersHelper
  
  def js_check_bid_price
    "if ($('bidder_bid').value.strip().length == 0) {
      alert('Il faut spécifier un prix!');
      return;
    }
    form.submit();"
  end
  
end