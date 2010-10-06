# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_date(date, format = :long)
    date.to_date.to_s(format)
  end
  
  def get_flash_message
    if flash[:alert]
      wrap_flash_message flash[:alert], :alert
    elsif flash[:notice]
      wrap_flash_message flash[:notice], :notice
    end
  end

  def wrap_flash_message(msg, flash_type)
    content_tag(:div, msg, :class => "flash #{flash_type}")
  end

  def display_flashes(msg = nil, flash_type = nil)
    msg = msg.present? ? wrap_flash_message(msg, flash_type) : get_flash_message
    content_tag(:div, :id => 'flash') do
      content_tag(:div, msg, :class => 'wrapper')
    end
  end
  
  # if resource has remote_id then open popup for VRBO login/pass; otherwise render simple link to destroy action
  def link_to_destroy_assignment resource
    if resource.remote_id?
      link_to 'destroy', resource_path(resource), :class => 'destroy_assignment'
    else
      link_to 'destroy', resource_path(resource), :method => 'delete', :confirm => 'Are you sure?'
    end
  end
end
