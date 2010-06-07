module VariousHelper
  # This is obviously a bad name
  # As this library grows, always be on the lookout for ways to group the helper methods
  # in a separate files as, for example, the tabs helper
    
  def haml_pagination
    haml_tag :div, :class => "group w-pagination" do
      haml_concat page_links( :disabled_page => 'disabled' )
    end
  end
  
  # Hack so that link_to accepts a block 
  # http://opensoul.org/2006/8/4/tip-overriding-link_to-to-accept-a-block
  # def link_to(*args, &block)
  #   if block_given?
  #     concat super(capture(&block), *args), block.binding
  #   else
  #     super(*args)
  #   end
  # end

  # TODO: merge with current implementation
  # def display_flash
  #   if !flash.empty?
  #     
  #     haml_tag :div, :class => "area w-flash" do
  #       flash.each do |f, value|
  #         haml_tag :div, :class => f do
  #           # haml_tag :div, :class => "header" do
  #           #   haml_tag :h1 do
  #           #     puts f.to_s
  #           #   end
  #           # end
  #           haml_tag :div, :class => "body" do
  #             haml_concat value
  #           end
  #         end
  #       end
  #     end
  #     
  #   end
  # end
  
end