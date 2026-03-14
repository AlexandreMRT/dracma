# frozen_string_literal: true

module Api
  class RefreshController < BaseController
    def create
      job = FetchQuotesJob.perform_later
      render_json({ enqueued: true, job_id: job.job_id }, status: :accepted)
    end
  end
end
