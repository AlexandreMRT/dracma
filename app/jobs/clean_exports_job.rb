# frozen_string_literal: true

class CleanExportsJob < ApplicationJob
  queue_as :default

  # Delete export files older than 30 days to prevent disk space leaks.
  # Accepts an optional exports_dir for testability.
  def perform(max_age_days: 30, exports_dir: nil)
    exports_dir = Pathname.new(exports_dir || Rails.root.join("exports"))
    return unless exports_dir.exist?

    cutoff = max_age_days.days.ago
    deleted = 0

    Dir.glob(exports_dir.join("*")).each do |file|
      next unless File.file?(file)
      next unless File.mtime(file) < cutoff

      File.delete(file)
      deleted += 1
    end

    Rails.logger.info("CleanExportsJob: deleted #{deleted} export files older than #{max_age_days} days")
  end
end
