module TeachingPlanHelper
  def teaching_plan_destroy?(teaching_plan)
    teaching_plan.teacher.id == current_teacher.try(:id) || current_user.current_role_is_admin_or_employee?
  end
end
