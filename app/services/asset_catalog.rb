# frozen_string_literal: true
# typed: true

# Static catalog of tracked assets, ported from Python assets.py
module AssetCatalog
  extend T::Sig

  IBOVESPA_STOCKS = {
    # Bancos e Financeiro
    "BBAS3.SA" => { name: "Banco do Brasil", sector: "Bancário" },
    "BBDC3.SA" => { name: "Bradesco ON", sector: "Bancário" },
    "BBDC4.SA" => { name: "Bradesco PN", sector: "Bancário" },
    "ITUB3.SA" => { name: "Itaú Unibanco ON", sector: "Bancário" },
    "ITUB4.SA" => { name: "Itaú Unibanco PN", sector: "Bancário" },
    "SANB11.SA" => { name: "Santander Brasil", sector: "Bancário" },
    "BPAC11.SA" => { name: "BTG Pactual", sector: "Bancário" },
    "INBR32.SA" => { name: "Banco Inter", sector: "Bancário" },
    "NU" => { name: "Nubank", sector: "Bancário" },
    "BBSE3.SA" => { name: "BB Seguridade", sector: "Seguros" },
    "IRBR3.SA" => { name: "IRB Brasil RE", sector: "Seguros" },
    "PSSA3.SA" => { name: "Porto Seguro", sector: "Seguros" },
    "B3SA3.SA" => { name: "B3", sector: "Serviços Financeiros" },

    # Holdings
    "ITSA4.SA" => { name: "Itaúsa PN", sector: "Holding" },

    # Petróleo e Gás
    "PETR3.SA" => { name: "Petrobras ON", sector: "Petróleo e Gás" },
    "PETR4.SA" => { name: "Petrobras PN", sector: "Petróleo e Gás" },
    "PRIO3.SA" => { name: "PetroRio", sector: "Petróleo e Gás" },
    "RECV3.SA" => { name: "PetroReconcavo", sector: "Petróleo e Gás" },
    "UGPA3.SA" => { name: "Ultrapar", sector: "Petróleo e Gás" },
    "CSAN3.SA" => { name: "Cosan", sector: "Petróleo e Gás" },
    "VBBR3.SA" => { name: "Vibra Energia", sector: "Petróleo e Gás" },
    "RAIZ4.SA" => { name: "Raízen", sector: "Petróleo e Gás" },

    # Mineração e Siderurgia
    "VALE3.SA" => { name: "Vale", sector: "Mineração" },
    "CSNA3.SA" => { name: "CSN", sector: "Siderurgia" },
    "GGBR4.SA" => { name: "Gerdau PN", sector: "Siderurgia" },
    "GOAU4.SA" => { name: "Metalúrgica Gerdau PN", sector: "Siderurgia" },
    "USIM5.SA" => { name: "Usiminas PNA", sector: "Siderurgia" },
    "BRAP4.SA" => { name: "Bradespar PN", sector: "Mineração" },
    "CMIN3.SA" => { name: "CSN Mineração", sector: "Mineração" },

    # Energia Elétrica
    "EGIE3.SA" => { name: "Engie Brasil", sector: "Energia Elétrica" },
    "EQTL3.SA" => { name: "Equatorial", sector: "Energia Elétrica" },
    "CPFE3.SA" => { name: "CPFL Energia", sector: "Energia Elétrica" },
    "CMIG4.SA" => { name: "Cemig PN", sector: "Energia Elétrica" },
    "ENGI11.SA" => { name: "Energisa", sector: "Energia Elétrica" },
    "TAEE11.SA" => { name: "Taesa", sector: "Energia Elétrica" },
    "CPLE3.SA" => { name: "Copel ON", sector: "Energia Elétrica" },
    "AURE3.SA" => { name: "Auren Energia", sector: "Energia Elétrica" },
    "ENEV3.SA" => { name: "Eneva", sector: "Energia Elétrica" },
    "NEOE3.SA" => { name: "Neoenergia", sector: "Energia Elétrica" },

    # Saneamento
    "SBSP3.SA" => { name: "Sabesp", sector: "Saneamento" },
    "CSMG3.SA" => { name: "Copasa", sector: "Saneamento" },
    "SAPR11.SA" => { name: "Sanepar", sector: "Saneamento" },

    # Telecomunicações
    "VIVT3.SA" => { name: "Telefônica Brasil", sector: "Telecomunicações" },
    "TIMS3.SA" => { name: "TIM", sector: "Telecomunicações" },
    "OIBR3.SA" => { name: "Oi ON", sector: "Telecomunicações" },

    # Varejo
    "MGLU3.SA" => { name: "Magazine Luiza", sector: "Varejo" },
    "LREN3.SA" => { name: "Lojas Renner", sector: "Varejo" },
    "AMER3.SA" => { name: "Americanas", sector: "Varejo" },
    "BHIA3.SA" => { name: "Casas Bahia", sector: "Varejo" },
    "PETZ3.SA" => { name: "Petz", sector: "Varejo" },
    "AZZA3.SA" => { name: "Azzas 2154", sector: "Varejo" },
    "LWSA3.SA" => { name: "Locaweb", sector: "Tecnologia" },
    "CASH3.SA" => { name: "Méliuz", sector: "Tecnologia" },
    "POSI3.SA" => { name: "Positivo", sector: "Tecnologia" },
    "GMAT3.SA" => { name: "Grupo Mateus", sector: "Varejo" },
    "ASAI3.SA" => { name: "Assaí", sector: "Varejo" },
    "PCAR3.SA" => { name: "Pão de Açúcar", sector: "Varejo" },
    "ALPA4.SA" => { name: "Alpargatas", sector: "Varejo" },
    "GRND3.SA" => { name: "Grendene", sector: "Varejo" },
    "VULC3.SA" => { name: "Vulcabras", sector: "Varejo" },

    # Alimentos e Bebidas
    "ABEV3.SA" => { name: "Ambev", sector: "Bebidas" },
    "BEEF3.SA" => { name: "Minerva", sector: "Alimentos" },
    "MDIA3.SA" => { name: "M. Dias Branco", sector: "Alimentos" },
    "SMTO3.SA" => { name: "São Martinho", sector: "Açúcar e Álcool" },

    # Saúde
    "RDOR3.SA" => { name: "Rede D'Or", sector: "Saúde" },
    "HAPV3.SA" => { name: "Hapvida", sector: "Saúde" },
    "FLRY3.SA" => { name: "Fleury", sector: "Saúde" },
    "RADL3.SA" => { name: "Raia Drogasil", sector: "Saúde" },
    "HYPE3.SA" => { name: "Hypera", sector: "Saúde" },
    "PNVL3.SA" => { name: "Dasa", sector: "Saúde" },
    "QUAL3.SA" => { name: "Qualicorp", sector: "Saúde" },

    # Construção Civil e Imobiliário
    "CYRE3.SA" => { name: "Cyrela", sector: "Construção" },
    "EZTC3.SA" => { name: "EZTEC", sector: "Construção" },
    "MRVE3.SA" => { name: "MRV", sector: "Construção" },
    "TEND3.SA" => { name: "Tenda", sector: "Construção" },
    "JHSF3.SA" => { name: "JHSF Participações", sector: "Construção" },
    "LAVV3.SA" => { name: "Lavvi", sector: "Construção" },
    "MULT3.SA" => { name: "Multiplan", sector: "Shoppings" },
    "IGTI11.SA" => { name: "Iguatemi", sector: "Shoppings" },

    # Indústria
    "WEGE3.SA" => { name: "WEG", sector: "Industrial" },
    "EMBJ3.SA" => { name: "Embraer", sector: "Aeronáutica" },
    "RAIL3.SA" => { name: "Rumo", sector: "Logística" },
    "ECOR3.SA" => { name: "Ecorodovias", sector: "Concessões" },
    "RENT3.SA" => { name: "Localiza", sector: "Locação de Veículos" },
    "MOVI3.SA" => { name: "Movida", sector: "Locação de Veículos" },
    "SUZB3.SA" => { name: "Suzano", sector: "Papel e Celulose" },
    "KLBN11.SA" => { name: "Klabin", sector: "Papel e Celulose" },
    "RANI3.SA" => { name: "Irani", sector: "Papel e Celulose" },
    "RAPT4.SA" => { name: "Randon", sector: "Industrial" },
    "LEVE3.SA" => { name: "Metal Leve", sector: "Industrial" },
    "POMO4.SA" => { name: "Marcopolo", sector: "Industrial" },

    # Transporte e Aviação
    "AZUL4.SA" => { name: "Azul", sector: "Aviação" },

    # Educação
    "YDUQ3.SA" => { name: "Yduqs", sector: "Educação" },
    "COGN3.SA" => { name: "Cogna", sector: "Educação" },

    # Outros
    "TOTS3.SA" => { name: "Totvs", sector: "Tecnologia" },
    "CVCB3.SA" => { name: "CVC", sector: "Turismo" },
    "VIVA3.SA" => { name: "Vivara", sector: "Varejo" },
    "BMOB3.SA" => { name: "Bmob3", sector: "Tecnologia" },
    "SLCE3.SA" => { name: "SLC Agrícola", sector: "Agronegócio" },
    "AGRO3.SA" => { name: "BrasilAgro", sector: "Agronegócio" },
    "GGPS3.SA" => { name: "GPS Participações", sector: "Holding" }
  }.freeze

  COMMODITIES = {
    "GC=F" => { name: "Ouro", sector: "Metal Precioso", unit: "oz" },
    "SI=F" => { name: "Prata", sector: "Metal Precioso", unit: "oz" },
    "PL=F" => { name: "Platina", sector: "Metal Precioso", unit: "oz" },
    "PA=F" => { name: "Paládio", sector: "Metal Precioso", unit: "oz" }
  }.freeze

  CRYPTO = {
    "BTC-USD" => { name: "Bitcoin", sector: "Criptomoeda", unit: "unidade" },
    "ETH-USD" => { name: "Ethereum", sector: "Criptomoeda", unit: "unidade" }
  }.freeze

  CURRENCY = {
    "USDBRL=X" => { name: "Dólar/Real", sector: "Câmbio", unit: "" }
  }.freeze

  US_STOCKS = {
    "AAPL" => { name: "Apple", sector: "Tecnologia" },
    "MSFT" => { name: "Microsoft", sector: "Tecnologia" },
    "GOOGL" => { name: "Alphabet (Google)", sector: "Tecnologia" },
    "AMZN" => { name: "Amazon", sector: "Tecnologia" },
    "META" => { name: "Meta (Facebook)", sector: "Tecnologia" },
    "NVDA" => { name: "NVIDIA", sector: "Tecnologia" },
    "TSLA" => { name: "Tesla", sector: "Automotivo" },
    "JPM" => { name: "JPMorgan Chase", sector: "Bancário" },
    "BAC" => { name: "Bank of America", sector: "Bancário" },
    "WFC" => { name: "Wells Fargo", sector: "Bancário" },
    "GS" => { name: "Goldman Sachs", sector: "Bancário" },
    "JNJ" => { name: "Johnson & Johnson", sector: "Saúde" },
    "UNH" => { name: "UnitedHealth", sector: "Saúde" },
    "PFE" => { name: "Pfizer", sector: "Farmacêutico" },
    "KO" => { name: "Coca-Cola", sector: "Bebidas" },
    "PEP" => { name: "PepsiCo", sector: "Bebidas" },
    "MCD" => { name: "McDonald's", sector: "Restaurantes" },
    "WMT" => { name: "Walmart", sector: "Varejo" },
    "XOM" => { name: "Exxon Mobil", sector: "Petróleo e Gás" },
    "CVX" => { name: "Chevron", sector: "Petróleo e Gás" }
  }.freeze

  sig { returns(T::Hash[String, T::Hash[Symbol, String]]) }
  def self.all
    {}.merge(IBOVESPA_STOCKS).merge(US_STOCKS).merge(COMMODITIES).merge(CRYPTO).merge(CURRENCY)
  end

  sig { params(ticker: String).returns(String) }
  def self.asset_type_for(ticker)
    return "stock" if IBOVESPA_STOCKS.key?(ticker)
    return "us_stock" if US_STOCKS.key?(ticker)
    return "commodity" if COMMODITIES.key?(ticker)
    return "crypto" if CRYPTO.key?(ticker)
    return "currency" if CURRENCY.key?(ticker)

    "stock"
  end

  sig { params(ticker: String).returns(T::Boolean) }
  def self.brazilian?(ticker)
    IBOVESPA_STOCKS.key?(ticker)
  end

  sig { params(ticker: String).returns(T::Hash[Symbol, String]) }
  def self.info(ticker)
    all[ticker] || { name: "Desconhecido", sector: "Outro" }
  end
end
