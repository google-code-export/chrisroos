module Egg
  require 'date'
  class Account
    def initialize(currency, number)
      @currency, @number = currency, number
    end
    attr_reader :currency, :number
  end
  class Money
    def initialize(money)
      money = money.sub(/£/, '').gsub(/,/, '')
      md = money.match(/(\d+\.\d+) ([A-Z]+)/)
      @money = md ? Float(md[1]) : 0
      @money = -@money if md && md[2] == 'DR'
    end
    def to_f
      @money
    end
  end
  class Statement
    def initialize(statement_date, closing_balance, account)
      from_date, to_date = statement_date.split(' to ')
      @from_date = Date.parse(from_date).strftime('%Y%m%d')
      @to_date = Date.parse(to_date).strftime('%Y%m%d')
      @closing_balance = Money.new(closing_balance).to_f
      @account = account
      @transactions = []
    end
    attr_reader :from_date, :to_date, :closing_balance, :transactions
    def add_transaction(transaction)
      @transactions << transaction
    end
    def account_currency
      @account.currency
    end
    def account_number
      @account.number
    end
  end
  require 'digest/md5'
  class Transaction
    def initialize
      # MAYBE INITIALIZE WITH A STATEMENT SO THAT WE CAN SET DATES FOR UNKNOWN ITEMS TO THE EARLIEST DATE OF THE STATEMENT
      @ofx_id, clean_description = nil, nil
    end
    def money=(money)
      @amount = Money.new(money).to_f
    end
    attr_reader :amount
    def date=(date)
      @date = Date.parse(date).strftime('%Y%m%d') rescue ''
    end
    attr_reader :date
    def description=(description)
      @description = description.squeeze(' ')
    end
    attr_reader :description
    def ofx_id
      @ofx_id ||= Digest::MD5.hexdigest(to_s)
    end
    def to_s
      [date, description, amount].join(', ')
    end
    def type
      if description =~ /INTEREST/
        'INT'
      else
        (amount < 0) ? 'DEBIT' : 'CREDIT'
      end
    end
  end
end

require 'rubygems'
require 'hpricot'

html = File.open('statements.aspx.html') { |f| f.read }
doc = Hpricot(html)

# card_type = (doc/"span#lblCardTypeName").inner_html
card_number = (doc/"span#lblCardNumber").inner_html
statement_date = (doc/"span#lblStatementDate").inner_html
closing_balance = ((doc/"table#tblTransactionsTable"/"tfoot"/"tr").first/"td").inner_html

account = Egg::Account.new('£', card_number)
statement = Egg::Statement.new(statement_date, closing_balance, account)

(doc/"table#tblTransactionsTable"/"tbody"/"tr").each do |row|
  date = (row/"td.date").inner_text
  description = (row/"td.description").inner_text
  money = (row/"td.money").inner_text
  transaction = Egg::Transaction.new
  transaction.date = date
  transaction.description = description
  transaction.money = money
  statement.add_transaction(transaction) unless transaction.description == 'OPENING BALANCE'
end

require 'ofx'
ofx_s = Ofx::Statement.new(statement)
puts ofx_s.to_xml