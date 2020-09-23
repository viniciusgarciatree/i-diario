class StudentReportDataForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :student_id

  validates :unity_id, :classroom_id, :student_id, presence: true
end

