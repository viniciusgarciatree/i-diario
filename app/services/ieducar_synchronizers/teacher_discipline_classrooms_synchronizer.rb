class TeacherDisciplineClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_teacher_discipline_classrooms(
      HashDecorator.new(
        api.fetch(
          ano: year,
          escola: unity_api_code
        )['vinculos']
      )
    )
  end

  private

  def api_class
    IeducarApi::TeacherDisciplineClassrooms
  end

  def update_teacher_discipline_classrooms(teacher_discipline_classrooms)
    ActiveRecord::Base.transaction do
      teacher_discipline_classrooms.each do |teacher_discipline_classroom_record|
        existing_discipline_api_codes = []

        (teacher_discipline_classroom_record.disciplinas || []).each do |discipline_api_code|
          existing_discipline_api_codes << discipline_api_code

          create_or_update_teacher_discipline_classrooms(teacher_discipline_classroom_record, discipline_api_code)
        end

        discard_inexisting_teacher_discipline_classrooms(
          teacher_discipline_classrooms_to_discard(
            teacher_discipline_classroom_record,
            existing_discipline_api_codes
          )
        )
      end
    end
  end

  def create_or_update_teacher_discipline_classrooms(teacher_discipline_classroom_record, discipline_api_code)
    teacher_id = teacher(teacher_discipline_classroom_record.servidor_id).try(:id)

    return if teacher_id.blank?

    classroom_id = classroom(teacher_discipline_classroom_record.turma_id).try(:id)

    return if classroom_id.blank?

    discipline_id = discipline(discipline_api_code).try(:id)

    return if discipline_id.blank?

    TeacherDisciplineClassroom.unscoped.find_or_initialize_by(
      api_code: teacher_discipline_classroom_record.id,
      year: year,
      teacher_id: teacher_id,
      teacher_api_code: teacher_discipline_classroom_record.servidor_id,
      discipline_id: discipline_id,
      discipline_api_code: discipline_api_code,
      classroom_id: classroom_id,
      classroom_api_code: teacher_discipline_classroom_record.turma_id,
      score_type: teacher_discipline_classroom_record.tipo_nota
    ).tap do |teacher_discipline_classroom|
      teacher_discipline_classroom.allow_absence_by_discipline =
        teacher_discipline_classroom_record.permite_lancar_faltas_componente
      teacher_discipline_classroom.changed_at = teacher_discipline_classroom_record.updated_at
      teacher_discipline_classroom.period = teacher_discipline_classroom_record.turno_id
      teacher_discipline_classroom.active = true if teacher_discipline_classroom.active.nil?
      teacher_discipline_classroom.save! if teacher_discipline_classroom.changed?

      teacher_discipline_classroom.discard_or_undiscard(false)
    end
  end

  def discard_inexisting_teacher_discipline_classrooms(teacher_discipline_classrooms_to_discard)
    teacher_discipline_classrooms_to_discard.each do |teacher_discipline_classroom|
      teacher_discipline_classroom.discard_or_undiscard(true)
    end
  end

  def teacher_discipline_classrooms_to_discard(teacher_discipline_classroom_record, existing_discipline_api_codes)
    if teacher_discipline_classroom_record.deleted_at.present?
      TeacherDisciplineClassroom.where(api_code: teacher_discipline_classroom_record.id)
    else
      TeacherDisciplineClassroom.unscoped
                                .where(
                                  api_code: teacher_discipline_classroom_record.id,
                                  score_type: teacher_discipline_classroom_record.tipo_nota
                                )
                                .where.not(discipline_api_code: existing_discipline_api_codes)
    end
  end
end