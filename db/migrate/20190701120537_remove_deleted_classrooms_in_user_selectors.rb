class RemoveDeletedClassroomsInUserSelectors < ActiveRecord::Migration
  def change
    Classroom.with_discarded.discarded.each do |classroom|
      classroom.users.each do |user|
        user.without_auditing do
          user.update(current_classroom_id: nil)
        end
      end
    end
  end
end
