class AssignmentsController < InheritedResources::Base
  rescue_from RemoteAssignmentError, :with => :show_errors
  
  before_filter :before_destory, :only => [:destroy]
  
  def create
    create!(:location => collection_url, :notice => 'Assignment was created successfully.')
  end
  
  def update
    update!(:location => collection_url, :notice => 'Assignment was updated successfully.')
  end
  
  # import assignemnts from vrbo.com
  def import
    Assignment.import_from_remote_reservations(params[:vrbo_login], params[:vrbo_password], params[:vrbo_listing_id], current_user, params[:year])
    
    flash[:notice] = 'Assignments were imported successfully.'
    respond_to do |format|
      format.html{redirect_to collection_url}
    end
  end
  
  private
    def begin_of_association_chain
      current_user
    end
    
    def collection
      @assignemnts ||= end_of_association_chain.by_start_time.paginate(:page => params[:page], :per_page => 15)
    end
    
    def show_errors(err)
      flash[:alert] = "Error: #{err.to_s}"
      respond_to do |format|
        format.html{redirect_to collection_url}
      end
    end
    
    def before_destory
      resource.remote_login = params[:vrbo_login]
      resource.remote_password = params[:vrbo_password]
    end
end
