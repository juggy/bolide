# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include Clearance::Authentication

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  layout 'public'

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :map_meta
  after_filter :insert_meta

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  def meta_path
    @@META_MAPPINGS[File.join(controller_path, action_name)]
  end

  def map_meta
    begin
      set_meta meta_path["title"],
               meta_path["description"],
               meta_path["keywords"]
    rescue NoMethodError => no_method_error
      set_meta "#{controller_name} #{action_name.capitalize}",
               "#{controller_name} #{action_name.capitalize}",
               "#{controller_name}"
    end
  end

  def set_meta(title, description, keywords)
    meta_site         = @@META_MAPPINGS["site"]
    @meta_title       = "#{title} | #{meta_site["name"]}".titlecase
    @meta_description = "#{meta_site["name"]}, #{description}".titlecase
    @meta_keywords    = "#{keywords}".titlecase
  end

  def insert_meta
    unless @insert_meta
      @insert_meta = true
      response.body.sub! /<head profile=\"http:\/\/gmpg.org\/xfn\/11\">/,
                         "<head profile=\"http://gmpg.org/xfn/11\">\n" \
                         "\t<title>#{ @meta_title }</title>\n" \
                         "\t<meta name=\"description\" content=\"#{ @meta_description }\" />\n" \
                         "\t<meta name=\"keywords\" content=\"#{ @meta_keywords }\" />\n" \
    end
  end
end
