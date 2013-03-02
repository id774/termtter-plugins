# -*- encoding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))
require 'yahoo_stock'
require 'yahoojp_stock'

class Numeric
  def yen
    i, f = self.to_s.split('.')
    i = i.reverse.scan(/\d{1,3}/).join(',').reverse 
    i = "-#{i}" if self < 0
    f ? "#{i}.#{f}" : i
  end
end

module Termtter::Client
  class << self
    def print_find_stock(header, values, format)
      printf "<green>#{format}</green>".termcolor + "\n",  *header

      values.each do |value|
        next if value.length < 6               #remove error data
        value.delete_at(2) if value.length > 6 #remove error data
        printf "<yellow>#{format}</yellow>".termcolor + "\n", *value
      end
    end
  end

  register_command(
    :name => :stock_find, :alias => :stf,
    :help => ['stock_find,stf COMPANY_NAME', 'Find Stock Symbol'],
    :exec => lambda do |name|
      begin
        case name
        when /^[A-Z]/
          res = YahooStock::ScripSymbol.new(name)
          header = res.data_attributes
          values = res.results(:to_array).output
          header[-1], header[-2] = header[-2], header[-1]
          values.each { |val| val[-1], val[-2] = val[-2], val[-1] }
          format = "%-12s%-30s%-11s%-7s%-9s%-30s"
        else
          header, *values = YahooJPStock::Find.new(name).output
          format = "%-8s%-12s%-40s%-15s%-15s%-15s"
        end
        print_find_stock(header, values, format)
      rescue
        puts 'Stock Not Found'
      end
    end
  )

  class << self
    def print_stock_price(data)
      data.each do |quote|
        quote = quote.transpose
        name, symbol = quote.shift(2)
        printf "<red>- %s[%s] -</red>\n".termcolor, name[1], symbol[1]
        quote.each do |name, val|
          color = val =~ /^-\d/ ? 'red' : 'yellow'
          print "<green>#{name} :</green> <#{color}>#{val}</#{color}>  ".termcolor
        end
        print "\n"
      end
    end
  end

  register_command(
    :name => :stock_price, :alias => :stp,
    :help => ['stock_price,stp [-r|s] SYMBOLS', 'Show Stock Price Data'],
    :exec => lambda do |symbols|
      case symbols.to_i
      when 0
        opt = :standard
        symbols.sub!(/\s*-(r|s)\s*/) { opt = $1 == 'r' ? :realtime : :standard; nil }
        quotes = YahooStock::Quote.new(:stock_symbols => symbols.split(/\s+/))
        quotes.send(opt)
        output = quotes.results(:to_hash).output
        output.map! do |q|
          q.delete(:ticker_trend)
          name, symbol = q.delete(:name), q.delete(:symbol)
          q.to_a.unshift([:name, name], [:symbol, symbol]).transpose
        end
      else 
        output = symbols.split(/\s+/).map { |symbol| YahooJPStock::Quote.new(symbol).output(:to_array) }
      end
      print_stock_price(output)
    end
  )

  class << self
    def print_stock_history(titles, values)
      printf "<green>%10s</green>".termcolor * titles.length + "\n", *titles
      values.reverse_each do |val|
        date, *val = val
        date.gsub!(/(\D)(\d)(?=\D)/) { $1 + '0' + $2 }
        printf "<red>%10s</red>".termcolor +
               "<yellow>%10s</yellow>".termcolor * val.length + "\n", date, *val
      end
    end
  end

  register_command(
    :name => :stock_history, :alias => :sth,
    :help => ['stock_history,sth SYMBOL [FROM] [TO]', 'Show Stock History Data'],
    :exec => lambda do |arg|
      begin
        symbol = arg[/^(\w+|\d+)/]
        from, to = arg.scan(/\d{4}[-\/]\d{1,2}[-\/]\d{1,2}/)
        term = arg[/:(daily|weekly|monthly)/]
        start_date = Date.parse(from) rescue Date.today-10
        end_date = Date.parse(to) rescue Date.today-1
        term = term ? term : :daily

        case symbol.to_i
        when 0
          titles, *values = 
            YahooStock::History.new(:stock_symbol => symbol,
                                    :start_date => start_date,
                                    :end_date => end_date
                                   ).values_with_header.split("\n").map { |line| line.split(",") }

        else
          titles, *values = YahooJPStock::History.new(symbol, start_date, end_date, term).output
        end
        print_stock_history(titles, values)
      rescue
        puts 'Stock Not Found or Date Range Not Good'
      end
    end
  )

  class << self
    def stock_prices(stock)
      current_price = stock.current_price[1].gsub(/\D+/, '').to_i
      day_change = stock.day_change[1].tr('（）', '()')
      last_trade_price = stock.last_trade_price[1].gsub(',', '')[/\d+/].to_i
      return current_price, day_change, last_trade_price
    end

    def print_portfolios(q, print_data)
      printf "<red>%s[%s]</red>\n".termcolor, q.name[1], q.symbol[1]
      print_data.each do |title, value|
        color = value =~ /^-\d/ ? 'red' : 'yellow'
        printf " <green>%s: </green><#{color}>%s</#{color}>".termcolor, title, value
      end
      print "\n"
    end

    def print_indices(indices)
      indices.each do |name, value|
        q = YahooJPStock::Quote.new(value)
        printf "<red>%s: </red>".termcolor, "#{name}"
        printf "<green>%s</green> <yellow>%s</yellow> ".termcolor * 2,
               q.current_price[0], q.current_price[1], q.day_change[0], q.day_change[1]
      end
      print "\n"
    end

    def print_total(total_value, total_profit, total_pratio, total_change, total_cratio)
      print "<red>Portfolio Value</red>\n".termcolor
      printf " <green>%s: </green><yellow>%s</yellow>  ".termcolor,
             '評価額', total_value.yen
      color = total_profit.yen =~ /^-\d/ ? 'red' : 'yellow'
      printf "<green>%s: </green><#{color}>%s(%+.2f%%)</#{color}>  ".termcolor,
             '含み損益', total_profit.yen, total_pratio
      color = total_change.yen =~ /^-\d/ ? 'red' : 'yellow'
      printf "<green>%s: </green><#{color}>%s(%+.2f%%)</#{color}>\n".termcolor,
             '前日比',  total_change.yen, total_cratio
    end
  end

  register_command(
    :name => :stock_portfolio, :alias => :stpo,
    :help => ['stock_portfolio,stpo', 'Show Your Portfolio Current Value'],
    :exec => lambda do |arg|
      begin
        indices = [[:日経平均, '998407'], [:Topix, '998405']]
        print_indices(indices)

        portfolios = config.plugins.stock

        total_value, total_profit, total_cost, total_last_value = 0, 0, 0, 0
        portfolios.each do |code, vol, buy|
          q = YahooJPStock::Quote.new(code) 
          current_price, day_change, last_trade_price = stock_prices(q)
          current_value = current_price * vol
          cost = buy.to_f * vol
          profit = current_value - cost
          pratio = (profit / cost * 100.00).to_s[/.*\.\d{2}/]

          print_data = [['現在値', current_price.yen], ['前日比', day_change], 
                       ['損益', "#{profit.yen}(#{pratio}%)"], ['評価額', current_value.yen],
                       ['買値', buy.to_f.yen], ['数量', vol.yen] ]

          print_portfolios(q, print_data)

          total_value += current_value
          total_last_value += last_trade_price * vol
          total_cost += cost
          total_profit += profit
        end
        total_pratio = total_profit / total_cost * 100.00
        total_change = total_value - total_last_value
        total_cratio = 100.00 * total_change / total_value

        print_total(total_value, total_profit, total_pratio, total_change, total_cratio)
      rescue => e
        puts "Error: " + e
        puts "setup your data at .termtter/config?"
        puts " ex. config.plugins.stock = [['4689.t', 1000, 28000], ['7203.t', 3500, 6520.30]]"
      end
    end
  )
end
