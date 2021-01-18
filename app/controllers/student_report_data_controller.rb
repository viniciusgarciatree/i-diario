class StudentReportDataController < ApplicationController
  before_action :require_current_teacher

  def form
    @student_report_data_form = StudentReportDataForm.new(unity_id: current_unity.id)
    authorize(StudentReportData, :show?)
  end

  def report
    @student_report_data_form = StudentReportDataForm.new(resource_params)

    authorize(StudentReportData, :show?)

    if @student_report_data_form.valid?

      student_report_data = StudentReportData.new(current_configuration)

      unity = current_unity
      classroom = Classroom.find(@student_report_data_form.classroom_id)
      grade = classroom.grade
      course = grade.course
      year = current_school_year
      if @student_report_data_form.student_id != ""
         student = Student.find(@student_report_data_form.student_id)
         report = student_report_data.build({
                 unity_id: unity.api_code,
                 course_id: course.api_code,
                 grade_id: grade.api_code,
                 classroom_id: classroom.api_code,
         	    student_id: student.api_code,
                 ano: year
               })
      else
         report = student_report_data.build({
                 unity_id: unity.api_code,
                 course_id: course.api_code,
                 grade_id: grade.api_code,
                 classroom_id: classroom.api_code,
         	    student_id: '',
                 ano: year
               })
      end


      send_pdf(t("routes.student_report_data"), report)
    else
      render :form
    end
  end

  protected

  def unities
    @unities = [current_unity]
  end
  helper_method :unities

  def classrooms
    @classrooms = Classroom.by_unity_and_teacher(current_unity.try(:id), current_teacher.id)
                           .ordered
  end
  helper_method :classrooms

  def resource_params
    params.require(:student_report_data_form).permit(
      :unity_id, :classroom_id, :student_id
    )
  end
end

