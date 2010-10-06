class Assignment < ActiveRecord::Base
  attr_accessor :save_on_remote_server, :remote_login, :remote_password, :remote_listing_id
  
  STATUSES = %w(RESERVE HOLD UNAVAILABLE CANCEL)
  BUSY_STATUSES = %w(RESERVE UNAVAILABLE)
  
  belongs_to :user
  
  validates_inclusion_of  :status, :in => STATUSES
  validates_presence_of   :start_at, :end_at, :user_id
  validates_uniqueness_of :remote_id, :scope => :user_id, :unless => Proc.new{|a| a.remote_id.blank?}
  
  validates_length_of :zip, :country, :maximum=>20
  validates_length_of :state, :maximum=>20
  validates_length_of :first_name, :last_name, :phone, :fax, :mobile, :city, :address1, :address2, :email, :maximum=>70
  validates_length_of :notes, :maximum=>3000
  validates_length_of :inquiry_source, :maximum=>50
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i , :allow_blank => true

  validates_numericality_of :num_adults, :num_children, :only_integer => true, :less_than_or_equal_to => 1000
  validates_numericality_of :num_adults, :num_children, :greater_than_or_equal_to => 0

  validate :validate_dates, :validate_for_another_assignment

  validates_presence_of :remote_login, :remote_password, :remote_listing_id, :if => :save_on_remote_server?
  
  before_create :set_recently_created
  before_save :sync_with_remote_server, :if => :save_on_remote_server?
  after_destroy :destroy_on_remote_server, :if => Proc.new{|a| a.remote_id.present?}
  
  named_scope :by_start_time, :order => 'start_at ASC'
  named_scope :busy, :conditions => {:status => BUSY_STATUSES}
  named_scope :for_listing, lambda{|listing_id|{ :conditions => {:listing_id => listing_id} }}
  

  def start_date
    start_at.to_date
  end
  
  def start_hour
    start_at.hour
  end
  
  def end_date
    end_at.to_date
  end
  
  def end_hour
    end_at.hour
  end
  
  def full_name
    [first_name, last_name].compact.join(' ')
  end
  
  def recently_created?
    @recently_created == true
  end
  
  def save_on_remote_server?
    @save_on_remote_server.present? and (@save_on_remote_server.to_i == 1 || @save_on_remote_server == true)
  end
  
  def save_on_remote_server
    @save_on_remote_server.present? ? save_on_remote_server? : remote_id?
  end
  
  # Import assignments from remote server
  def self.import_from_remote_reservations(vrbo_login, vrbo_password, vrbo_listing_id, user, year)
    ra = RemoteAssignment.new(vrbo_login, vrbo_password, vrbo_listing_id)
    reservations = ra.reservations(year)
    reservations.each do |reservation|
      unless Assignment.exists?(:remote_id => reservation.remote_id)
        reservation.user = user
        reservation.save_on_remote_server = false
        reservation.save!
      end
    end
  end
  
  def remote_listing_id
    @remote_listing_id || self.listing_id
  end
private
  # sync assignment with remote server if it's required
  def sync_with_remote_server
    begin
      if recently_created? || remote_id.blank?
        create_on_remote_server
      else
        update_on_remote_server
      end
    rescue RemoteAssignmentError => e
      errors.add(:save_on_remote_server, e.to_s)
      false
    end
  end
  
  def update_on_remote_server
    RemoteAssignment.update_reservation(self)
  end
  
  def create_on_remote_server
    RemoteAssignment.create_reservation(self)
  end
  
  def destroy_on_remote_server
    logger.debug { "message #{self.remote_login}" }
    RemoteAssignment.destroy_reservation(self)
  end
  
  def set_recently_created
    @recently_created = true
  end
  
  # don't allow to start_at be greater than end_at
  def validate_dates
    if start_at && end_at
      errors.add(:end_at, 'should be greater than start date') if end_at <= start_at
    end
  end
  
  # don't allow create more than one assignment with status UNAVAILABLE or RESERVE in same period
  def validate_for_another_assignment
    if start_at && end_at && BUSY_STATUSES.include?(self.status)
      errors.add(:start_at, 'Another assignment already exists for these dates.') if user.assignments.busy.for_listing(self.listing_id).exists?([" ? < end_at AND ? > start_at", self.start_at, self.end_at])
    end
  end
end
