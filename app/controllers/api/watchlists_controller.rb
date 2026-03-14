# frozen_string_literal: true

module Api
  class WatchlistsController < BaseController
    def index
      watchlists = current_user.watchlists.order(:ticker)
      render_json({ total: watchlists.size, watchlists: watchlists.map { |watchlist| watchlist_payload(watchlist) } })
    end

    def create
      payload = watchlist_params
      ticker = payload[:ticker].to_s.upcase
      return render_error("Ticker is required", status: :unprocessable_entity) if ticker.blank?

      watchlist = current_user.watchlists.find_or_initialize_by(ticker: ticker)
      watchlist.notes = payload[:notes] if payload.key?(:notes)
      created = watchlist.new_record?
      watchlist.save!

      render_json({ watchlist: watchlist_payload(watchlist) }, status: created ? :created : :ok)
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
    end

    def destroy
      watchlist = current_user.watchlists.find_by(id: params[:id]) ||
                  current_user.watchlists.find_by(ticker: params[:id].to_s.upcase) ||
                  current_user.watchlists.find_by(ticker: "#{params[:id].to_s.upcase}.SA")
      return render_error("Watchlist entry not found", status: :not_found) unless watchlist

      watchlist.destroy!
      render_json({ deleted: true, watchlist: watchlist_payload(watchlist) })
    end

    private

    def watchlist_payload(watchlist)
      {
        id: watchlist.id,
        ticker: watchlist.ticker,
        notes: watchlist.notes,
        created_at: watchlist.created_at,
        updated_at: watchlist.updated_at
      }
    end

    def watchlist_params
      params.fetch(:watchlist, params).permit(:ticker, :notes)
    end
  end
end
