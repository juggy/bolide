ActionController::Routing::Routes.draw do |map|
  
  map.with_options :conditions=>{:subdomain=>'admin'} do |admin|
    admin.resources :accounts
  end
  
  map.resources :msg, :controller=>'msgs'
  map.resources :q, :controller=>'qs'

end
