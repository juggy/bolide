
module UiHelper
  def with_tooltip(tooltip, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    concat "<span class=\"with-qtip\">"
    proc.call
    concat "<div class=\"qtip hidden\">#{tooltip}</div>"
    concat "</span>"
  end
  
  def group(name = nil, options = {}, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    html_options = options[:html]
    if html_options
      tag_options = html_options
    else
      tag_options = {}
    end
    
    classes = tag_options[:class]
    classes = "" if (classes.nil?)
    classes += " group"
    tag_options[:class] = classes
    
    concat tag("div", tag_options, true)
    concat "<div class=\"header\"><h5 class=\"title\">#{name}</h5></div>" if name
    concat "<div class=\"body\">"
    proc.call
    concat "</div></div>" 
  end
  
  def tab_group(options = {}, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    html_options = options[:html]
    if html_options
      html_options = html_options.stringify_keys
      tag_options = tag_options(html_options)
    else
      tag_options = {}
    end
    
    classes = tag_options[:class]
    classes = "" if (classes.nil?)
    classes += " w-tabs"
    tag_options[:class] = classes
    
    concat tag("div", tag_options, true)
    concat "<ul>"
    proc.call
    concat "</ul><div class=\"clearer\"></div></div>" 
    ""
  end
  
  def tab(name, url = "#", options = {})
    html_options = options[:html]
    if html_options
      html_options = html_options.stringify_keys
      tag_options = tag_options(html_options)
    else
      tag_options = {}
    end
    
    if options.delete(:selected)
      classes = tag_options[:class]
      classes = "" if (classes.nil?)
      classes += " selected"
      tag_options[:class] = classes
    end
    
    concat tag("li", tag_options, true)
    concat link_to(name, url)
    concat "</li>"
    ""
  end
  
  def sidebar_group(options = {}, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    html_options = options[:html]
    if html_options
      html_options = html_options.stringify_keys
      tag_options = tag_options(html_options)
    else
      tag_options = {}
    end
    
    classes = tag_options[:class]
    classes = "" if (classes.nil?)
    classes += " group actions"
    tag_options[:class] = classes
    
    concat tag("div", tag_options, true)
    concat "<div class=\"body\"><ul class=\"vlist\">"
    proc.call
    concat "</ul></div></div>" 
    ""
  end
  
  def sidebar_row(&proc)
    raise ArgumentError, "Missing block" unless block_given?
    concat "<li>"
    concat proc.call
    concat "</li>"
    ""
  end

  def column_header(title = "&nbsp;", search_obj = nil, field = nil)
    clazz = ""
    clazz = "selectable " + order_class(search_obj, {:by => field}) if search_obj
    html = "<th class=\"#{clazz}\">"
    html << "<span class=\"label\">"
    if(search_obj)
      html << order_without_class(search_obj, {:by => field, :as => title})
    else
      html << title
    end
    html << "</span></th>"
  end

  
  def ui_form_for(object, *args, &proc)
    options = args.extract_options!
    form_for(object, *(args << options.merge!(:html=>{:class=>"w-form-h"})), &proc)
    concat "<div class=\"clearer\">&nbsp;</div>"
  end
  
  def remote_ui_form_for(object, *args, &proc)
    options = args.extract_options!
    remote_form_for(object, *(args << options.merge!(:html=>{:class=>"w-form-h"})), &proc)
    concat "<div class=\"clearer\">&nbsp;</div>"
  end
  
  def filter_for(search, title = "Filtre de recherche", *args, &proc)
    options = args.extract_options!
    help = options.delete(:help)
    old_filters = options.delete(:filters)
    
    concat "<div class=\"ProjectFilter\"><div class=\"header\"><h4 class=\"left\"><span class=\"title T\">"
    concat title
    concat "</span></h4>"
    if help && !help.blank?
      concat "<div class=\"left w-hoverexpandable\">"
      concat "<span class=\"help with-qtip\"><span>?</span><div class=\"qtip hidden\">"
      concat help      
      concat "</div></span></div>"
    end
    if(old_filters)
      concat "<div class=\"right w-hoverexpandable\">"
      concat button("Filtre...")
      concat "<div class=\"details w-drawer when-hover w-menu-v\">"
      concat "<ul>"
      old_filters.each do |f|
        concat "<li><span class=\"label\"><a href=\"#{f.url}\">#{f.name}</a></span></li>"
      end
      concat "</ul></div></div>"
    end
    
    concat "<div class=\"clearer\">&nbsp;</div></div>"
    concat "<div class=\"body\">"

    ui_form_for(search, *(args << options), &proc)
    concat "</div></div>"
  end
  
  def form_header(title, options = {})
    html_options = options.delete(:html)
    if html_options
      html_options = html_options.stringify_keys
      tag_options = tag_options(html_options)
    else
      tag_options = {}
    end
    
    help = options.delete(:help)
    
    html = tag("h1", tag_options, true)
    html << "<h1><div class=\"left title\">#{title}</div>"
    if help && !help.blank?
      html << "<div class=\"right w-hoverexpandable\">"
      html << "<span class=\"help with-qtip\">"
      html << "<span>?</span><div class=\"qtip hidden\">"
      html << help      
      html << "</div></span></div>"
    end
    html << "<div class=\"clearer\">&nbsp;</div></h1>"
  end
  
  def start_sequence(html_options, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    if html_options
      html_options = html_options.stringify_keys
      tag_options = tag_options(html_options)
    else
      tag_options = {}
    end
    tag_options.merge!({"class" => "steps"})
    
    html = tag("ul", tag_options, true)
    sequences = []
    proc.call(sequences)

    sequences.each_index do |i|
      value = sequences[i]
      
      name = value[:name]
      subname = value[:subname]
      url = value[:url]
      options = value[:options]
      
      if options
        options = options.stringify_keys
        tag_options = tag_options(options)
      else
        options = {}
      end
      
      sclass = "step"
      sclass << "first" if i == 0
      sclass << "current" if value[:current]
      sclass << "with-two-lines" if subname && !subname.blank?
      
      html << tag("li", {"class" => sclass}, true)
      html << tag("a", nil, true)
      html << tag("span", {"class"=>"label"}, true)
      html << name
      html << tag("br")
      if subname && !subname.blank?
        html << tag("span", {"class" => "smaller"}, true)
        html << "#{subname}</span>"
      end
      html << "</span></a></li>"
    end
    html << "</ul>"
  end
  
  def sequence(name, subname = nil, selected = false, options = "")
    {:name => name, :subname => subname, :current => selected, :url=>url_for(options), :options=>options}
  end
  
  def category(name, count)
    html = tag "span", {"class" => "category"}, true
    html += tag "span", {"class" => "label"}, true
    html += "#{ERB::Util.h(name)}</span>"
    html += tag "span", {"class" => "count"}, true
    html += "#{count}</span></span>"
  end
  
  def button(name = "", url_options = nil, options = {})
    html_options = options[:html]
    if html_options
      tag_options = html_options
    else
      tag_options = {}
    end

    icon = options[:icon]
     
    bclass = ""
    bclass += options[:size].to_s if options[:size] #small/big
    bclass += " #{options[:type]}" if options[:type] #create/update/delete
    bclass += " with-icon" if icon
    bclass += " without-text" if name.blank?
    clazz = tag_options[:class]
    bclass = clazz + " " + bclass if clazz
    tag_options[:class] = bclass
    
    tag_options["data-update"] = options.delete(:update) if options[:update]
    tag_options["data-url"] = url_for(url_options) if(url_options)
    tag_options["data-remote"] = "true" if options[:remote]
    tag_options["data-method"] = options[:method] if options[:method]
    tag_options.merge!("type"=>"submit")
    
    html = tag "button", tag_options , true
    html += "<span>"
    html += "<img align=\"absmiddle\" src=\"#{icon}\"/>" if icon
    html += "#{ERB::Util.h(name)}</span></button>"
  end
  
  protected
  
  # COPIED FROM SEARCHLOGIC PLUGIN
  #
  # Creates a link that alternates between acending and descending. It basically
  # alternates between calling 2 named scopes: "ascend_by_*" and "descend_by_*"
  #
  # By default Searchlogic gives you these named scopes for all of your columns, but
  # if you wanted to create your own, it will work with those too.
  #
  # Examples:
  #
  #   order @search, :by => :username
  #   order @search, :by => :created_at, :as => "Created"
  #
  # This helper accepts the following options:
  #
  # * <tt>:by</tt> - the name of the named scope. This helper will prepend this value with "ascend_by_" and "descend_by_"
  # * <tt>:as</tt> - the text used in the link, defaults to whatever is passed to :by
  # * <tt>:ascend_scope</tt> - what scope to call for ascending the data, defaults to "ascend_by_:by"
  # * <tt>:descend_scope</tt> - what scope to call for descending the data, defaults to "descend_by_:by"
  # * <tt>:params</tt> - hash with additional params which will be added to generated url
  # * <tt>:params_scope</tt> - the name of the params key to scope the order condition by, defaults to :search
  def order_without_class(search, options = {}, html_options = {})
    options[:params_scope] ||= :search
    if !options[:as]
      id = options[:by].to_s.downcase == "id"
      options[:as] = id ? options[:by].to_s.upcase : options[:by].to_s.humanize
    end
    options[:ascend_scope] ||= "ascend_by_#{options[:by]}"
    options[:descend_scope] ||= "descend_by_#{options[:by]}"
    ascending = search.order.to_s == options[:ascend_scope]
    new_scope = ascending ? options[:descend_scope] : options[:ascend_scope]
    url_options = {
      options[:params_scope] => search.conditions.merge( { :order => new_scope } )
    }.deep_merge(options[:params] || {})
    link_to options[:as], url_for(url_options)
  end
  
  def order_class(search, options = {})
    options[:params_scope] ||= :search
    if !options[:as]
      id = options[:by].to_s.downcase == "id"
      options[:as] = id ? options[:by].to_s.upcase : options[:by].to_s.humanize
    end
    options[:ascend_scope] ||= "ascend_by_#{options[:by]}"
    options[:descend_scope] ||= "descend_by_#{options[:by]}"
    ascending = search.order.to_s == options[:ascend_scope]
    selected = [options[:ascend_scope], options[:descend_scope]].include?(search.order.to_s)
    if selected
      if ascending
        return "order-asc"
      else
        return "order-desc"
      end
    end
    ""
  end
  
end