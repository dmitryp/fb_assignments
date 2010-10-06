require 'rubygems'
require 'mechanize'
require "addressable/uri"
require 'ostruct'

class RemoteAssignment
  attr_accessor :listing_id
  
  def initialize(login, password, listing_id = nil)
    @agent = Mechanize.new
    @login = login
    @password = password
    @listing_id = listing_id
    
    login!
  end
  
  def agent
    @agent
  end
  
  # collect links to edit reservation forms, parse them and return resarvations
  def reservations(year = nil)
    page = search_reservations(year)
    links = page.links.find_all{|l| l.text =~ /Edit\sDetails/}
    links.map{|l| build_reservation(l.href)}
  end
  
  # create new reservation
  def self.create_reservation(assignment)
    RemoteAssignment.save_reservation(assignment, true)
  end
  
  # update exisiting reservation
  def self.update_reservation(assignment)
    RemoteAssignment.save_reservation(assignment, false)
  end
  
  def self.save_reservation(assignment, new_record = false)
    r = RemoteAssignment.new(assignment.remote_login, assignment.remote_password, assignment.remote_listing_id)

    url = new_record ? "https://connect.homeaway.com/reservations/create.htm?sessionId=#{r.session_id}" : "https://connect.homeaway.com/reservations/edit.htm?sessionId=#{r.session_id}&id=#{assignment.remote_id}"
    page = r.agent.get(url)
    form = page.form('reservationForm')
    
    form.arrivalDateString = assignment.start_date.to_s(:us_date)
    form.checkinTime       = assignment.start_hour
    form.departureDateString = assignment.end_date.to_s(:us_date)
    form.checkoutTime = assignment.end_hour
    form.status = assignment.status
    form.inquirySource = assignment.inquiry_source
    form.notes = assignment.notes
    form.firstName = assignment.first_name
    form.lastName = assignment.last_name
    form.email = assignment.email
    form.numAdults = assignment.num_adults
    form.numChildren = assignment.num_children
    form.phone = assignment.phone
    form.mobile = assignment.mobile
    form.fax = assignment.fax
    form.addr1 = assignment.address1
    form.addr2 = assignment.address2
    form.city = assignment.city
    form.stateProvince = assignment.state
    form.zip = assignment.zip
    form.country = assignment.country
    
    page = r.agent.submit(form)
    raise RemoteAssignmentError, 'Impossible to save assignment on the remote server' if page.form('reservationForm').present?
    # return true if reservationForm not present after submit
    true
  end

  # destroy exisiting reservation
  def self.destroy_reservation(assignment)
    r = RemoteAssignment.new(assignment.remote_login, assignment.remote_password, assignment.listing_id)
    page = r.agent.get("https://connect.homeaway.com/reservations/delete.htm?sessionId=#{r.session_id}&id=#{assignment.remote_id}")
  end
  
  def session_id
    @session_id ||= get_session_id
  end
private
  
  # login into VRBO.com
  def login!
    page = @agent.get('https://admin.vrbo.com/admin/Logon.aspx')
    form = page.form('Form1')
    # use send method because input name contains '$'.
    form.send('logonControl$UserId=', @login)
    form.send('logonControl$Pass=', @password)
    page = @agent.submit(form)
    raise RemoteAssignmentError, 'Invalid login or password for Virbo account'  if page.form('Form1').present?
    true
  end
  
  # Post a reservation search form
  def search_reservations(year = nil)
    params = { 'periodType' => 'periodTypeYear', 'searchMode' => 0, 'sortBy' => 'ARRIVAL_DATE',
      'sortByAscending' => 'true', 'status' => 'All', 'submit' => 'Find', 'year' => year || Date.today.year
    }
    @agent.get("https://connect.homeaway.com/reservations/list.htm?sessionId=#{session_id}", params)
  end

  # parse a reservation edit form and build reservation
  def build_reservation(link)
    page = @agent.get("https://connect.homeaway.com#{link}")
    form = page.form('reservationForm')
    
    reservation = Assignment.new do |r|
      r.remote_id     = get_reservation_id(link)
      r.start_at      = DateTime.parse(form.arrivalDateString + " " + form.checkinTime)
      r.end_at        = DateTime.parse(form.departureDateString + " " + form.checkoutTime)
      r.notes         = form.notes
      r.status        = form.status
      r.first_name    = form.firstName
      r.last_name     = form.lastName
      r.email         = form.email
      r.num_adults    = form.numAdults.to_i
      r.num_children  = form.numChildren.to_i
      r.phone         = form.phone
      r.mobile        = form.mobile
      r.fax           = form.fax
      r.address1      = form.addr1
      r.address2      = form.addr2
      r.city          = form.city
      r.state         = form.stateProvince
      r.zip           = form.zip
      r.country       = form.country
      r.inquiry_source = form.inquirySource
      r.listing_id = @listing_id
    end
  end

  # extract reservation id from url
  def get_reservation_id(link)
    uri = Addressable::URI.parse(link)
    uri.query_values['id']
  end
  
  # get calendar for listing
  # 'https://admin.vrbo.com/admin/calendar.aspx?listing=305472'
  def get_vrbo_calendar_page
    check_lisitng_id
    
    url = "https://admin.vrbo.com/admin/calendar.aspx?listing=#{@listing_id}"
    @agent.get(url)
  end
  
  # get sessionId for connect.homeaway.com
  def get_session_id
    check_lisitng_id
    
    calendar_frame = get_vrbo_calendar_page.iframes.first.src
    page = @agent.get calendar_frame
    link = page.links[3].href
    uri = Addressable::URI.parse(link)
    uri.query_values['sessionId']
  end
  
  def check_lisitng_id
    raise RemoteAssignmentError, 'Missing listing id' if @listing_id.nil?
  end
end