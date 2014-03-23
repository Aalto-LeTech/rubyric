class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.login_field = :email
    c.crypto_provider = Authlogic::CryptoProviders::SCrypt
    c.transition_from_crypto_providers = Authlogic::CryptoProviders::Sha512
    #c.validate_password_field = false
    #c.validate_email_field = false
    #c.transition_from_restful_authentication = true
  end

  belongs_to :organization
  
  validates_uniqueness_of :login, :allow_nil => true
  validates_uniqueness_of :email, :allow_nil => true

  attr_accessible :firstname, :lastname, :email, :password, :password_confirmation

  has_many :group_members
  has_many :groups, :through => :group_members
  #has_and_belongs_to_many :groups
  
  has_many :reviews, :order => 'id'          # reviews as a grader

  has_many :group_reviewers
  has_many :assigned_groups, :through => :group_reviewers, :source => :group

  # has_many :group_reviewers
  # has_many :groups_to_review, :order => 'id', :through => :group_reviewers

  # TODO: filter inactive courses
  has_and_belongs_to_many :course_instances_student, {:class_name => 'CourseInstance', :join_table => 'course_instances_students', :order => :course_instance_id}
  has_and_belongs_to_many :course_instances_assistant, {:class_name => 'CourseInstance', :join_table => 'assistants_course_instances', :order => :course_instance_id}
  has_and_belongs_to_many :courses_teacher, {:class_name => 'Course', :join_table => 'courses_teachers', :order => :code}


  def name
    if firstname.blank? && lastname.blank?
      email
    else
      "#{firstname} #{lastname}"
    end
  end

  def admin?
    self.admin
  end

  def teacher?
    courses_teacher.size > 0
  end

end
