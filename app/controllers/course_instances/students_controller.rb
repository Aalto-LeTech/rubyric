class CourseInstances::StudentsController < CourseInstancesController
  before_action :login_required

  def show
    @course_instance = CourseInstance.find(params[:course_instance_id])
    load_course
    authorize! :update, @course_instance

    @students = @course_instance.students
    
    respond_to do |format|
      format.html { }
      format.json { render :json => @students }
    end
    log "students view #{@course_instance.id}"
  end

end
