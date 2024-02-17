class User < ApplicationRecord
  has_many :enrollments
  has_many :programs, through: :enrollments
  has_many :teachers, through: :enrollments, source: :teacher
  # Enum for user roles
  enum kind: { student: 0, teacher: 1, student_teacher: 2 }

  validates :name, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 0 }

  validate :validate_kind

  # Scope for users with favorite enrollments
  scope :favorites, -> {
    includes(:enrollments)
      .where(enrollments: { favorite: true })
  }

  # Class Method to find classmates of a user
  def self.classmates(user)
    joins(enrollments: :program)
        .where(enrollments: { program_id: user.enrollments.select(:program_id) })
        .where.not(id: user.id)
        .distinct
  end

  private

  def validate_kind
    return unless kind_changed? # Check if the 'kind' attribute has changed

    # Validate user roles based on enrollments
    if teacher? && enrollments.exists?
      errors.add(:kind, "can not be teacher because is studying in at least one program")
    elsif student? && Enrollment.where(teacher: self).exists?
      errors.add(:kind, "can not be student because is teaching in at least one program")
    end
  end

end
