module ApplicationHelper
  include ActiveSupport::Inflector

  PROFILE_DEFAULT_PICTURE_PATH = 'https://apps-ieducar-images.s3.amazonaws.com/i-diario/profile-default.jpg'.freeze

  def unread_notifications_count
    @unread_notifications_count ||= current_user.unread_notifications.count
  end

  def last_system_notifications
    @last_system_notifications ||= current_user.system_notifications.limit(10).ordered
  end

  def system_notification_path(notification)
    SystemNotificationRouter.path(notification)
  end

  def unities
    @unities ||= Unity.ordered
  end

  def resource
    instance_variable_get("@#{controller_name.singularize}")
  end

  def tagfy(value)
    transliterate(value).tr(' ', '_').underscore
  end

  def breadcrumbs
    Navigation.draw_breadcrumbs(controller_name, self)
  end

  def menus
    key = [
      'Menus',
      controller_name,
      current_user.current_user_role&.role&.cache_key || current_user.cache_key,
      Translation.cache_key
    ]

    Rails.cache.fetch(key, expires_in: 1.day) do
      Navigation.draw_menus(controller_name, current_user)
    end
  end

  def shortcuts
    key = [
      'HomeShortcuts',
      current_user.current_user_role&.role&.cache_key || current_user&.cache_key,
      Translation.cache_key
    ]

    Rails.cache.fetch(key, expires_in: 1.day) do
      Navigation.draw_shortcuts(current_user)
    end
  end

  def title
    Navigation.draw_title(controller_name, false, self)
  end

  def title_with_icon
    Navigation.draw_title(controller_name, true, self)
  end

  def simple_form_for(object, *args, &block)
    options = args.extract_options!
    options[:builder] ||= Portabilis::FormBuilder

    super object, *(args << options), &block
  end

  def profile_picture_tag(user, profile_picture_html_options = {})
    user_avatar_url = user_avatar_url(user)

    image_tag(user_avatar_url, profile_picture_html_options.merge(onerror: on_error_img)) if user_avatar_url
  end

  def user_avatar_url(user)
    Rails.cache.fetch [:user_avatar_url, current_entity.id, user.cache_key] do
      user.profile_picture&.url ||
        IeducarAvatarAuth.new(user.student&.avatar_url.to_s).generate_new_url.presence ||
        PROFILE_DEFAULT_PICTURE_PATH
    end
  end

  def on_error_img
    "this.error=null;this.src=#{PROFILE_DEFAULT_PICTURE_PATH}"
  end

  def custom_date_format(date)
    if date == Time.zone.today
      t('date.today')
    elsif date == Time.zone.yesterday
      t('date.yesterday')
    elsif date.year == Time.zone.today.year
      l(date, format: :short)
    else
      l(date, format: :long)
    end
  end

  def filename(file)
    file.path.split('/').last
  end

  def t_boolean(value)
    value ? t('boolean.yes') : t('boolean.no')
  end

  def number_of_classes_elements(number_of_classes)
    elements = []
    (1..number_of_classes).each do |i|
      elements << { id: i, name: i, text: i }
    end
    elements.to_json
  end

  def decimal_input_mask(number_of_decimal_places)
    if number_of_decimal_places
      { data: { inputmask: "'digits': #{number_of_decimal_places}" } }
    else
      { data: { inputmask: "'digits': 0" } }
    end
  end

  def entity_copyright
    Rails.cache.fetch("#{Entity.current.try(:id)}_entity_copyright", expires_in: 10.minutes) do
      "© #{GeneralConfiguration.current.copyright_name} #{Time.zone.today.year}"
    end
  end

  def entity_website
    Rails.cache.fetch("#{Entity.current.try(:id)}_entity_website", expires_in: 10.minutes) do
      GeneralConfiguration.current.support_url
    end
  end

  def alert_by_entity(_entity_name)
    ''
  end

  def initial_value_for_select2_remote(id, description)
    '{"id": ' + id.to_s + ', "description": "' + description.tr("\n", ' ') + '"}'
  end

  def link_to_if_and_else(*args, &block)
    condition = args.shift
    content = capture(&block)

    if condition
      link_to(*args) do
        content
      end
    else
      content
    end
  end

  def present(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)

    yield(presenter) if block_given?
  end

  def default_steps
    (Bimesters.to_select + Trimesters.to_select + Semesters.to_select + BimestersEja.to_select).uniq
  end

  def teacher_profiles_options
    cache_key = ['TeacherProfileList', current_entity.id, current_user.teacher&.cache_key]

    Rails.cache.fetch(cache_key, expires_in: 1.day) do
      TeacherProfilesOptionsGenerator.new(current_user).run!
    end
  end

  def use_teacher_profile?
    current_user.can_use_teacher_profile? &&
      current_user.teacher &&
      current_user.teacher.teacher_profiles.present?
  end

  def current_user_available_disciplines
    return [] unless current_user_classroom && current_teacher

    @current_user_available_disciplines ||=
      Discipline.by_teacher_id(current_teacher).by_classroom(current_user_classroom).ordered
  end

  def current_unities
    @current_unities ||=
      if current_user.current_user_role.try(:role_administrator?)
        Unity.ordered
      else
        [current_unity]
      end
  end

  def current_user_available_years
    return [] if current_unity.blank?

    @current_user_available_years ||= current_user.available_years(current_unity)
  end

  def current_user_available_teachers
    return [] if current_unity.blank? || current_user_classroom.blank?

    @current_user_available_teachers ||= begin
      teachers = Teacher.by_unity_id(current_unity)
                        .by_classroom(current_user_classroom)
                        .order_by_name

      if current_school_calendar.try(:year)
        teachers.by_year(current_school_calendar.try(:year))
      else
        teachers
      end
    end
  end

  def current_user_available_classrooms
    return [] if current_unity.blank?

    @current_user_available_classrooms ||= begin
      classrooms = if current_teacher.present? && current_user.teacher?
                     Classroom.by_unity_and_teacher(current_unity, current_teacher).ordered
                   else
                     Classroom.by_unity(current_unity).ordered
                   end

      if current_school_calendar.try(:year)
        classrooms.by_year(current_school_calendar.try(:year))
      else
        classrooms
      end
    end
  end

  def back_link(name, path)
    content_for :back_link do
      back_link_tag(name, path)
    end
  end

  def back_link_tag(name, path)
    link_to path, class: 'back-link' do
      raw <<-HTML
        <i class="icon-append fa fa-angle-left"></i>
        #{name}
      HTML
    end
  end

  def include_recaptcha_js
    return '' if recaptcha_site_key.blank?

    raw %Q{
      <script src="https://www.google.com/recaptcha/api.js?render=#{recaptcha_site_key}"></script>
    }
  end

  def recaptcha_execute
    return '' if recaptcha_site_key.blank?

    id = "recaptcha_token_#{SecureRandom.hex(10)}"

    raw %Q{
      <input name="recaptcha_token" type="hidden" id="#{id}"/>
      <script>
        grecaptcha.ready(function() {
          grecaptcha.execute('#{recaptcha_site_key}').then(function(token) {
            document.getElementById("#{id}").value = token;
          });
        });
      </script>
    }
  end

  private

  def recaptcha_site_key
    @recaptcha_site_key ||= Rails.application.secrets.recaptcha_site_key
  end
end
