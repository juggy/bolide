module TabsHelper
  
  def tabs
    haml_tag :div, {:class => 'w-tabs group'} do
      haml_tag :ul, {:class => 'tabs'} do
        yield
      end
    end
  end
  
  def tab(title, url = "#", options = {})
    link_options = {}
    if options[:highlight]
      link_options[:class] = 'active' if options[:highlight]
    else
      link_options[:class] = 'active' if current_page?( url )
    end
    
    haml_tag :li, {:class => 'tab'} do
      haml_concat link_to( title, url, link_options)
    end
  end
  
end