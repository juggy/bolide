ActionController::Routing::Routes.draw do |map|
  map.what 'what', :controller => 'view/base', :action => 'what'
  map.how 'how', :controller => 'view/base', :action => 'how'
  map.api 'api', :controller => 'view/base', :action => 'api'
  map.root :controller => 'view/base', :action => 'index'
end
