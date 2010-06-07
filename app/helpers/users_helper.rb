module UsersHelper
  def generate_address_book_shortcut(user)
    "http://#{EXTRANET_DOMAIN}/contacts/address_book/?access_key=#{user.access_key}"
  end
end