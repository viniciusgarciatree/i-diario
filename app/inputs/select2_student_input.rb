class Select2StudentInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    input_html_options[:readonly] = 'readonly' unless options[:admin_or_employee].presence
    input_html_options[:value] = input_value if input_html_options[:value].blank?

    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    students = []

    if options[:record]&.persisted?
      students = [options[:record].student]
    elsif options[:admin_or_employee].presence
      students = StudentEnrollmentClassroom.by_classroom(classroom.id).by_student(user.current_classroom_id)
    elsif user.current_teacher.present? && options[:classroom_id]
      students = StudentEnrollmentClassroom.by_classroom(classroom.id).by_student(user.current_classroom_id)
    end

    options[:elements] = students

    super
  end

  private

  def input_value
    return options[:record].student_id if options[:record]&.persisted?
  end
end

