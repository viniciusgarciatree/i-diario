class Teacher < ActiveRecord::Base
  acts_as_copy_target

  audited

  has_many :teacher_profiles, dependent: :destroy
  has_many :users
  has_many :teacher_discipline_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_discipline_classrooms
  has_many :unities, -> { distinct }, through: :classrooms

  validates :name, :api_code, presence: true
  validates :api_code, uniqueness: true
  validates :active, inclusion: { in: [true, false] }

  scope :by_id, ->(id) { where(id: id) }
  scope :by_unity_id, ->(unity_id) { by_unity_id(unity_id) }
  scope :by_year, ->(year) { filter_current_teachers_by_year(year) }
  scope :active, -> { active_query }
  scope :by_classroom, lambda { |classroom_id|
    joins(:teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: {
        classroom_id: classroom_id
      }
    )
  }
  scope :by_daily_frequency, lambda { |daily_frequency|
    joins(:teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: {
        classroom_id: daily_frequency.classroom_id,
        discipline_id: daily_frequency.discipline_id
      }
    )
  }

  scope :order_by_name, -> { order(name: :asc) }

  def self.active_query
    joins_teacher_discipline_classrooms.where(
      active: true
    ).uniq
  end

  def self.search(value)
    relation = all

    if value.present?
      relation = relation.where(%Q(
        name ILIKE :text OR api_code = :code
      ), text: "%#{value}%", code: value)
    end

    relation
  end

  def self.by_unity_id(unity_id)
    joins_teacher_discipline_classrooms.where(classrooms: { unity_id: unity_id })
                                       .active
                                       .uniq
  end

  def self.filter_current_teachers_by_year(year)
    joins_teacher_discipline_classrooms.where(
      classrooms: {year: year}
    )
  end

  def to_s
    name
  end

  def self.joins_teacher_discipline_classrooms
    joins(:teacher_discipline_classrooms).joins(
      arel_table.join(Classroom.arel_table)
        .on(
          Classroom.arel_table[:id]
            .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
        )
        .join_sources
    )
  end
end
