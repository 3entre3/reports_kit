module ReportsKit
  class Params
    attr_accessor :report_key, :ui_filters

    def initialize(report_key:, ui_filters: {})
      self.report_key = report_key
      self.ui_filters = ui_filters
    end
  end
end
