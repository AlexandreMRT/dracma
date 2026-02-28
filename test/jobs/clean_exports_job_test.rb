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
      FileUtils.touch(old_file, mtime: 31.days.ago.to_time)

      CleanExportsJob.perform_now(exports_dir: dir)

      assert_not File.exist?(old_file), "Old file should have been deleted"
      assert_path_exists new_file, "New file should still exist"
    end
  end

  test "respects custom max_age_days parameter" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, "report.csv")
      File.write(file, "data")
      FileUtils.touch(file, mtime: 8.days.ago.to_time)

      CleanExportsJob.perform_now(max_age_days: 7, exports_dir: dir)

      assert_not File.exist?(file), "File older than 7 days should be deleted"
    end
  end

  test "handles non-existent exports directory gracefully" do
    nonexistent = "/tmp/nonexistent_dracma_exports_#{SecureRandom.hex(8)}"
    assert_nothing_raised { CleanExportsJob.perform_now(exports_dir: nonexistent) }
  end

  test "does not delete subdirectories" do
    Dir.mktmpdir do |dir|
      subdir = File.join(dir, "subdir")
      FileUtils.mkdir(subdir)
      FileUtils.touch(subdir, mtime: 60.days.ago.to_time)

      CleanExportsJob.perform_now(exports_dir: dir)

      assert File.directory?(subdir), "Subdirectories should not be deleted"
    end
  end
end
