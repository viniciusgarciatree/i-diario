class StudentReportData
  include ActiveModel::Model

  def initialize(configuration)
    @configuration = configuration
  end

  def build(params)
    report = api.fetch_student_report_data(params)

    Base64.decode64 report['encoded']
  end

  protected

  def api
    @api ||= IeducarApi::Students.new(@configuration.to_api)
  end
end

