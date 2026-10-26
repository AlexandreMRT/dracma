# frozen_string_literal: true

class YahooFinanceProvider
  def history(ticker, range: "max", interval: "1d")
    YahooFinanceClient.history(ticker, range: range, interval: interval)
  end

  def info(ticker)
    YahooFinanceClient.info(ticker)
  end
end
