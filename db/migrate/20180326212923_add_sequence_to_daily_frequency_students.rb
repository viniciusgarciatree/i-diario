class AddSequenceToDailyFrequencyStudents < ActiveRecord::Migration
  def change
    add_column :daily_frequency_students, :sequence, :integer
  end
end
