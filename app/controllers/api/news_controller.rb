# frozen_string_literal: true

module Api
  class NewsController < BaseController
    def index
      sentiment = params[:sentiment].presence
      if sentiment && !ApiDataService.valid_news_sentiment?(sentiment)
        return render_error("Invalid sentiment", status: :bad_request)
      end

      limit = parse_limit(params[:limit], default: 25)
      return render_error("Invalid limit", status: :bad_request) unless limit

      items = ApiDataService.news_items(sentiment: sentiment, limit: limit)
      render_json({ total: items.size, sentiment: sentiment || "all", news: items })
    end
  end
end
