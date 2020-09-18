class DisciplineLessonPlanClonerForm < ActiveRecord::Base
  has_no_table

  attr_accessor :discipline_lesson_plan_id, :teacher

  validates :discipline_lesson_plan_id, presence: true
  has_many :discipline_lesson_plan_item_cloner_form
  accepts_nested_attributes_for :discipline_lesson_plan_item_cloner_form, allow_destroy: true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          @classrooms = Classroom.where(id: discipline_lesson_plan_item_cloner_form.map(&:classroom_id).uniq)
          discipline_lesson_plan_item_cloner_form.each_with_index do |item, index|
            @current_item_index = index
            new_lesson_plan = discipline_lesson_plan.dup
            new_lesson_plan.teacher_id = teacher.id
            new_lesson_plan.lesson_plan = discipline_lesson_plan.lesson_plan.dup
            new_lesson_plan.lesson_plan.teacher = teacher
            new_lesson_plan.lesson_plan.original_contents = discipline_lesson_plan.lesson_plan.contents
            new_lesson_plan.lesson_plan.contents_created_at_position = {}
            new_lesson_plan.lesson_plan.original_contents.each_with_index do |content, position|
              new_lesson_plan.lesson_plan.contents_created_at_position[content.id] = position
            end

            new_lesson_plan.lesson_plan.original_objectives = discipline_lesson_plan.lesson_plan.objectives
            new_lesson_plan.lesson_plan.objectives_created_at_position = {}
            new_lesson_plan.lesson_plan.original_objectives.each_with_index do |objective, position|
              new_lesson_plan.lesson_plan.objectives_created_at_position[objective.id] = position
            end

            new_lesson_plan.lesson_plan.start_at = item.start_at
            new_lesson_plan.lesson_plan.end_at = item.end_at
            new_lesson_plan.lesson_plan.classroom = @classrooms.find_by_id(item.classroom_id)
            discipline_lesson_plan.lesson_plan.lesson_plan_attachments.each do |lesson_plan_attachment|
              new_lesson_plan.lesson_plan.lesson_plan_attachments << LessonPlanAttachment.new(
                attachment: lesson_plan_attachment.attachment
              )
            end
            new_lesson_plan.save!
          end
          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s
        message.slice!("A validação falhou: ")
        errors.add(:classroom_id, "Turma #{e.record.lesson_plan.try(:classroom)}: #{message}")
        discipline_lesson_plan_item_cloner_form[@current_item_index].errors.add(:classroom_id, message)
        return false
      end
    end
  end

  def discipline_lesson_plan
    @discipline_lesson_plan ||= DisciplineLessonPlan.includes(lesson_plan: [:objectives, :contents])
                                                    .find(discipline_lesson_plan_id)
  end
end
