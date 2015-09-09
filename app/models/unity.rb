class Unity < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit
  include Filterable

  has_enumeration_for :unit_type, with: UnitTypes, create_helpers: true

  belongs_to :author, class_name: "User"
  has_one :address, as: :source, inverse_of: :source

  has_many :origin_***REMOVED***, foreign_key: :origin_unity_id,
    class_name: "***REMOVED***Request"
  has_many :origin_***REMOVED***, foreign_key: :origin_unity_id,
    class_name: "***REMOVED***"
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***"
  has_many :destination_***REMOVED***, foreign_key: :destination_unity_id,
    class_name: "***REMOVED***"
  has_many :***REMOVED***_distribution_unities
  has_many :***REMOVED***, through: :***REMOVED***_distribution_unities
  has_many :moved_***REMOVED***
  has_many :***REMOVED***
  has_many :***REMOVED***
  has_many :classrooms
  has_many :teacher_discipline_classrooms, through: :classrooms

  has_and_belongs_to_many :***REMOVED***

  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  validates :author, :name, :unit_type, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, allow_blank: true

  scope :ordered, -> { order(arel_table[:name].asc) }
  scope :by_api_codes, lambda { |codes|
    where(arel_table[:api_code].in(codes))
  }
  scope :with_api_code, -> { where(arel_table[:api_code].not_eq("")) }
  scope :by_teacher, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }

  #search scopes
  scope :search_name, lambda { |search_name| where("name ILIKE ?", "%#{search_name}%") }
  scope :unit_type, lambda { |unit_type| where(unit_type: unit_type) }
  scope :phone, lambda { |phone| where("phone ILIKE ?", "%#{phone}%") }
  scope :email, lambda { |email| where("email ILIKE ?", "%#{email}%") }
  scope :responsible, lambda { |responsible| where("responsible ILIKE ?", "%#{responsible}%") }

  def to_s
    name
  end
end
