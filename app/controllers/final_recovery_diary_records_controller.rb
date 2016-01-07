class FinalRecoveryDiaryRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def index
    @final_recovery_diary_records = apply_scopes(FinalRecoveryDiaryRecord)
      .includes(
        recovery_diary_record: [
          :unity,
          :classroom,
          :discipline
        ]
      )
      .filter(filtering_params(params[:search]))
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered

    authorize @final_recovery_diary_records

    @classrooms = fetch_classrooms
    @disciplines = fetch_disciplines
  end

  def new
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.new.localized
    @final_recovery_diary_record.school_calendar = current_school_calendar
    @final_recovery_diary_record.build_recovery_diary_record
    @final_recovery_diary_record.recovery_diary_record.unity = current_user_unity

    @unities = fetch_unities
    @classrooms = fetch_classrooms

    @number_of_decimal_places = @final_recovery_diary_record.school_calendar.steps.to_a.last.test_setting.number_of_decimal_places
  end

  def create
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.new.localized
    @final_recovery_diary_record.assign_attributes(resource_params)

    authorize @final_recovery_diary_record

    if @final_recovery_diary_record.save
      respond_with @sfinal_recovery_diary_record, location: final_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @number_of_decimal_places = @final_recovery_diary_record.school_calendar.steps.last.test_setting.number_of_decimal_places

      students_in_final_recovery = fetch_students_in_final_recovery
      decorate_students(students_in_final_recovery)

      render :new
    end
  end

  def edit
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id]).localized

    authorize @final_recovery_diary_record

    students_in_final_recovery = fetch_students_in_final_recovery
    mark_students_not_in_final_recovery_for_destruction(students_in_final_recovery)
    add_missing_students(students_in_final_recovery)
    decorate_students(students_in_final_recovery)

    @unities = fetch_unities
    @classrooms = fetch_classrooms
    @number_of_decimal_places = @final_recovery_diary_record.school_calendar.steps.last.test_setting.number_of_decimal_places
  end

  def update
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id]).localized
    @final_recovery_diary_record.assign_attributes(resource_params)

    authorize @final_recovery_diary_record

    students_in_final_recovery = fetch_students_in_final_recovery
    decorate_students(students_in_final_recovery)

    if @final_recovery_diary_record.save
      respond_with @final_recovery_diary_record, location: final_recovery_diary_records_path
    else
      @unities = fetch_unities
      @classrooms = fetch_classrooms
      @number_of_decimal_places = @final_recovery_diary_record.school_calendar.steps.last.test_setting.number_of_decimal_places

      render :edit
    end
  end

  def destroy
    @final_recovery_diary_record = FinalRecoveryDiaryRecord.find(params[:id])

    @final_recovery_diary_record.destroy

    respond_with @final_recovery_diary_record, location: final_recovery_diary_records_path
  end

  private

  def resource_params
    params.require(:final_recovery_diary_record).permit(
      :school_calendar_id,
      recovery_diary_record_attributes: [
        :id,
        :unity_id,
        :classroom_id,
        :discipline_id,
        :recorded_at,
        students_attributes: [
          :id,
          :student_id,
          :score,
          :_destroy
        ]
      ]
    )
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(
      :by_classroom_id,
      :by_discipline_id,
      :by_recorded_at
    )
  end

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.by_unity_and_teacher(
      current_user_unity.id,
      current_teacher.id
    )
    .ordered
  end

  def fetch_disciplines
    Discipline.by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered
  end

  def fetch_students_in_final_recovery
    return unless @final_recovery_diary_record.recovery_diary_record.classroom_id && @final_recovery_diary_record.recovery_diary_record.discipline_id

    StudentsInFinalRecoveryFetcher.new(api_configuration)
      .fetch(
        @final_recovery_diary_record.recovery_diary_record.classroom_id,
        @final_recovery_diary_record.recovery_diary_record.discipline_id
      )
  end

  def mark_students_not_in_final_recovery_for_destruction(students_in_final_recovery)
    @final_recovery_diary_record.recovery_diary_record.students.each do |student|
      is_student_in_final_recovery = students_in_final_recovery.any? do |student_in_final_recovery|
        student.student.id == student_in_final_recovery.id
      end

      student.mark_for_destruction unless is_student_in_final_recovery
    end
  end

  def add_missing_students(students_in_final_recovery)
    students_missing = students_in_final_recovery.select do |student_in_final_recovery|
      @final_recovery_diary_record.recovery_diary_record.students.none? do |student|
        student.student.id == student_in_final_recovery.id
      end
    end

    students_missing.each do |student_missing|
      @final_recovery_diary_record.recovery_diary_record.students.build(student: student_missing)
    end
  end

  def decorate_students(students_in_final_recovery)
    @final_recovery_diary_record.recovery_diary_record.students.reject(&:marked_for_destruction?).each do |student|
      student.student = students_in_final_recovery.find { |student_in_final_recovery| student_in_final_recovery.id == student.student_id }
    end
  end

  def api_configuration
    IeducarApiConfiguration.current
  end
end