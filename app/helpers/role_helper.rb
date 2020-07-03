module RoleHelper
  FEATURES_YES_OR_NO = [
    'can_change_user_password',
    'ieducar_api_exam_posting_without_restrictions',
    'change_school_year',
    'infrequency_trackings',
    'pedagogical_trackings'
  ].freeze

  def access_level_tags(role_permission)
    tags = ''
    AccessLevel.list.each do |access_level|
      tags += ' data-level-' + access_level if role_permission.access_level_has_feature?(access_level)
    end
    tags
  end

  def permissions(feature)
    FEATURES_YES_OR_NO.include?(feature) ? PermissionsYesOrNo.to_select.to_json : Permissions.to_select.to_json
  end
end
