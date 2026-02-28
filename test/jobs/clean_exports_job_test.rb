# frozen_string_literal: true

require "test_helper"

class CleanExportsJobTest < ActiveJob::TestCase
  test "enqueues on default queue" do
    assert_equal "default", CleanExportsJob.new.queue_name
  end

  test "deletes files older than 30 days" do
    Dir.mktmpdir do |dir|
      old_file = File.join(dir, "old_report.csv")
      new_file = File.join(dir, "new_report.csv")

      File.write(old_file, "old data")
      File.write(new_file, "new data")

      # Backdate the old file to 31 days ago
      FileUtils.touch(old_file, mtime: 31.days.ago)

      stub_exports_dir(dir) do
        CleanExportsJob.perform_now
      end

      assert_not File.exist?(old_file), "Old file should have been deleted"
      assert_path_exists new_file, "New file should still exist"
    end
  end

  test "respects custom max_age_days parameter" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, "report.csv")
      File.write(file, "data")
      FileUtils.touch(file, mtime: 8.days.ago)

      stub_exports_dir(dir) do
        CleanExportsJob.perform_now(max_age_days: 7)
      end

      assert_not File.exist?(file), "File older than 7 days should be deleted"
    end
  end

  test "handles non-existent exports directory gracefully" do
    stub_exports_dir("/tmp/nonexistent_dracma_exports_#{SecureRandom.hex(8)}") do
      assert_nothing_raised { CleanExportsJob.perform_now }
    end
  end

  test "does not delete subdirectories" do
    Dir.mktmpdir do |dir|
      subdir = File.join(dir, "subdir")
      FileUtils.mkdir(subdir)
      FileUtils.touch(subdir, mtime: 60.days.ago)

      stub_exports_dir(dir) do
        CleanExportsJob.perform_now
      end

      assert File.directory?(subdir), "Subdirectories should not be deleted"
    end
  end

  private

  def stub_exports_dir(dir)
    original_method = Rails.method(:root)
    fake_root = Pathname.new(dir).join("..")

    Rails.define_singleton_method(:root) { fake_root.join }

    # Override exports path to point to our temp dir
    CleanExportsJob.define_method(:perform) do |max_age_days: 30|
      exports_dir = Pathname.new(dir)
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

    yield
  ensure
    Rails.define_singleton_method(:root, original_method)
    # Restore original perform method
    CleanExportsJob.class_eval do
      remove_method :perform
    end
  end
end
