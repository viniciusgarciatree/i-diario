class ContentsForDisciplineRecordFetcher
  def initialize(teacher, classroom, discipline, date)
    @teacher = teacher
    @classroom = classroom
    @discipline = discipline
    @date = date
  end

  def fetch
    @contents = []

    @contents = map_contents(lesson_plans) if lesson_plans.present?
    @contents = map_contents(teaching_plans) if @contents.blank? && teaching_plans.present?

    @contents
  end

  private

  def map_contents(plans)
    @contents = plans.map(&:contents).uniq.flatten
  end

  def lesson_plans
    @lesson_plans ||= begin
      lesson_plans = DisciplineLessonPlan.includes(lesson_plan: :contents)
                                         .by_classroom_id(@classroom.id)
                                         .by_discipline_id(@discipline.id)
                                         .by_date(@date)

      teacher_lesson_plans = lesson_plans.by_teacher_id(@teacher.id)
      filtered_lesson_plans = teacher_lesson_plans if teacher_lesson_plans.exists?

      other_lesson_plans = lesson_plans.by_other_teacher_id(@teacher.id)
      filtered_lesson_plans = other_lesson_plans if filtered_lesson_plans.blank? && other_lesson_plans.exists?

      filtered_lesson_plans
    end
  end

  def teaching_plans
    @teaching_plans ||= begin
      teaching_plans = DisciplineTeachingPlan.includes(teaching_plan: :contents)
                                             .by_unity(@classroom.unity_id)
                                             .by_grade(@classroom.grade_id)
                                             .by_discipline(@discipline.id)
                                             .by_year(school_calendar_year)
                                             .by_school_term(school_term)

      teacher_teaching_plans = teaching_plans.by_teacher_id(@teacher.id)
      filtered_teaching_plans = teacher_teaching_plans if teacher_teaching_plans.exists?

      other_teaching_plans = teaching_plans.by_other_teacher_id(@teacher.id)

      if filtered_teaching_plans.blank? && other_teaching_plans.exists?
        filtered_teaching_plans = other_teaching_plans
      end

      general_teaching_plans = teaching_plans.by_secretary

      if filtered_teaching_plans.blank? && general_teaching_plans.exists?
        filtered_teaching_plans = general_teaching_plans
      end

      filtered_teaching_plans
    end
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(@classroom)
  end

  def school_calendar_year
    steps_fetcher.school_calendar.try(:year) || @date.to_date.year
  end

  def raw_school_term
    step = steps_fetcher.step_by_date(@date.to_date)
    school_term = SchoolTermConverter.convert(step)
    school_term = '' if school_term.to_s == SchoolTermTypes::YEARLY.to_s
    school_term.to_s
  end

  def school_term
    school_terms = []
    school_terms << SchoolTerms::FIRST_BIMESTER_EJA if raw_school_term == SchoolTerms::FIRST_SEMESTER
    school_terms << SchoolTerms::SECOND_BIMESTER_EJA if raw_school_term == SchoolTerms::SECOND_SEMESTER
    [raw_school_term] + school_terms
  end
end
