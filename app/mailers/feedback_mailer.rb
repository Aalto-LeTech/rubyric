class FeedbackMailer < ActionMailer::Base
  default :from => RUBYRIC_EMAIL
  default_url_options[:host] = RUBYRIC_HOST
  
  # Sends the review by email to the students
  def review(review)
    @review = review
    @exercise = @review.submission.exercise
    @course_instance = @exercise.course_instance
    @course = @course_instance.course
    @grader = @review.user
    group = review.submission.group

    if !@course.email.blank?
      headers["Reply-to"] = @course.email
    elsif !@exercise.anonymous_graders && @grader && !@grader.email.blank?
      headers["Reply-to"] = @grader.email
    end

    # Collect receiver addresses
    recipients = []
    group.group_members.each do |member|
      if !member.email.blank?
        recipients << member.email
      elsif member.user && !member.user.email.blank?
        recipients << member.user.email
      end
    end

    if recipients.empty?
      # TODO: raise an exception with an informative message
      review.status = 'finished'
      review.save
      return
    end
    
    # Attachment
    unless @review.filename.blank?
      attachments[@review.filename] = File.read(@review.full_filename)
    end
    
    subject = "#{@course.full_name} - #{@exercise.name}"
    
    if review.type == 'AnnotationAssessment'
      template_name = 'annotation'
      @review_url = review_url(review.id, :group_token => group.access_token, :protocol => 'https://')
    else
      template_name = 'review'
    end
    
    I18n.with_locale(@course_instance.locale || I18n.locale) do
      mail(
        :to => recipients.join(","),
        :subject => subject,
        :template_path => 'feedback_mailer',
        :template_name => template_name
      )
      #:reply_to => from,
    end

    # Set status
    review.status = 'mailed'
    review.save
  end
  
  def bundled_reviews(course_instance, user, reviews, exercise_grades)
    return if user.email.blank?
    
    @reviews = reviews
    @exercise_grades = exercise_grades
    @course_instance = course_instance
    @course = @course_instance.course
    
    from = @course.email 
    from = RUBYRIC_EMAIL if from.blank?
    
    subject = "#{@course.full_name}"
    
    # Attachments
    @reviews.each do |review|
      attachments[review.filename] = File.read(review.full_filename) unless review.filename.blank?
    end
    
    I18n.with_locale(@course_instance.locale || I18n.locale) do
      mail(
        :to => user.email, :from => from, :subject => subject
      )
    end
  end
  
  def delivery_errors(errors)
    @errors = errors
    mail(:to => ERRORS_EMAIL, :subject => '[Rubyric] Undelivered feedback mails')
  end
  
  # Sends grades and feedback to A+
  def aplus_feedback(submission_id)
    submission = Submission.find(submission_id)
    group = submission.group
    @exercise = submission.exercise
    @course_instance = @exercise.course_instance
    @course = @course_instance.course
    max_grade = @exercise.max_grade
    subject = "#{@course.full_name} - #{@exercise.name}"
    peer_reviews_required = @exercise.peer_review_goal && @exercise.peer_review_goal > 0
    
    @reviews = []
    review_ids = []
    submission.reviews.each do |review|
      next unless review.include_in_results?
      @reviews << review
      review_ids << review.id
    end
    
    # Get final grade of the group. FIXME: repetition in ExercisesController#results
    grading_mode = begin 
        JSON.parse(@exercise.grading_mode || '{}')
      rescue Exception => e
        logger.warn "Invalid grading mode for exercise #{@exercise.id}: #{@exercise.grading_mode}\n#{e}"
        {}
      end
    logger.debug "GRADING MODE: #{grading_mode}"
      
    group_result = group.result(@exercise, grading_mode)
    combined_grade = Review.cast_grade(group_result[:grade])
    logger.debug "GRADE: #{group_result}"

    # A+ always requires max_grade
    if max_grade.nil?
      max_grade = 1
      combined_grade = 1
      logger.warn "No max_grade for exercise #{@exercise.id}."
    end
    
    # Get feedback (same for every member)
    feedback = I18n.with_locale(@course_instance.locale || I18n.locale) do
      render_to_string(action: :aplus).to_str
    end
    
    # Koodiaapinen hack Spring 2016
    # Convert points to pass/fail
    if [218, 235, 255, 257].include?(@exercise.id)
      if combined_grade >= 4.99
        combined_grade = max_grade
      else
        combined_grade = 0
      end
    end
      
    # Koodiaapinen hack Spring 2016 (Note: does not work correctly for group work)
    # Don't send feedback if the student has not conducted peer reviews
#     if @exercise.id == 218 || @exercise.id == 235
#       # Count reviews conducted by the user
#       valid_submission_ids = @exercise.submission_ids
#       max_review_count = 0
#       
#       File.open('peer_reviews.txt', 'a') do |file|
#         group.users.each do |student|
#           finished_review_count = 0
#           started_review_count = 0
#           Review.where(:user_id => student.id).find_each do |review|
#             next unless valid_submission_ids.include?(review.submission_id)
#             finished_review_count += 1 if ['finished', 'mailing', 'mailed', 'invalidated'].include?(review.status)
#             started_review_count += 1 if ['started'].include?(review.status) || review.status.blank?
#           end
#           
#           total_review_count = finished_review_count + started_review_count
#           max_review_count = total_review_count if total_review_count > max_review_count
#           
#           file.puts "#{max_review_count},#{finished_review_count} #{group.users.first.firstname} #{group.users.first.lastname}"
#         end
#       end
#     end
    
    # Have all members conducted peer reviews?
    peer_reviews_ok = !peer_reviews_required || group.users.all? { |student|
        student.peer_review_count(@exercise)[:finished_peer_reviews] >= @exercise.peer_review_goal
      }
    
    # Deliver
    success = true
    response = nil
    if group_result[:not_enough_reviews] || group_result[:no_submissions] || @reviews.empty?
      success = false
      logger.info "Not enough reviews for group #{group.id}"
    elsif combined_grade.nil? || combined_grade.is_a?(String)
      success = false
      logger.info "No numeric grade for group #{group.id}."
    elsif submission.aplus_feedback_url.blank?
      # Generate JSON for manual transfer
      object = {
        "students_by_email" => submission.group.group_members.map {|member| member.email },
        "feedback" => feedback,
        "grader" => 3832,
        "exercise_id" => 1719,
        "submission_time" => submission.created_at,
        "points" => (6 * combined_grade / max_grade).round
      }
      
      File.open('aplus_grades.json', 'a') do |file|
        file.print object.to_json
        file.puts ','
      end
    else
      if Rails.env == 'production'
        response = RestClient.post(submission.aplus_feedback_url, {points: combined_grade.round, max_points: max_grade.round, feedback: feedback})
        success = false unless response.code == 200
      else
        logger.debug "Skipping A+ API call in development environment. #{submission.aplus_feedback_url}, points: #{combined_grade.round}, max_points: #{max_grade.round}"
      end
    end
    
    if success
      Review.where(:id => review_ids).update_all(:status => 'mailed')
    else
      Review.where(:id => review_ids, :status => 'mailing').update_all(:status => 'finished')
      logger.error "Failed to submit points to A+"
      logger.error response
    end
  end

  def submission_received(submission_id)
    @submission = Submission.find(submission_id)
    @group = @submission.group
    @exercise = @submission.exercise
    @course_instance = @exercise.course_instance
    @course = @course_instance.course
    
    subject = "#{@course.full_name} - #{@exercise.name}"
    
    # FIXME: repetition, see review()
    recipients = []
    @group.group_members.each do |member|
      if !member.email.blank?
        recipients << member.email
      elsif member.user && !member.user.email.blank?
        recipients << member.user.email
      end
    end
    
    I18n.with_locale(@course_instance.locale || I18n.locale) do
      mail(
        :to => recipients.join(","),
        :subject => subject
      )
    end
    
  end
  
end
