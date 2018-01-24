require 'pusher-client'
require 'eventmachine'

class Orderbook
  attr_accessor :bids, :asks

  def initialize(bids = [], asks = [])
    @bids = bids
    @asks = asks
  end
end

class WS
  def initialize
    @socket = PusherClient::Socket.new('de504dc5763aeef9ff52')
  end

  def connect(async = false)
    @socket.connect(async)
  end

  def sub(channel_name)
    @socket.subscribe(channel_name)
  end

  def bind(channel_name, event, &callback)
    @socket[channel_name].bind(event) do |data|
      yield data
    end
  end
end

def ob_updated(data)
  puts "Order book"
  result = JSON.parse(data)

  ob = Orderbook.new
  result["bids"].each do |bid|
    ob.bids << { price: bid[0], amount: bid[1] }
  end
  result["asks"].each do |ask|
    ob.asks << { price: ask[0], amount: ask[1] }
  end

  puts "Bids: #{ob.bids}"
  puts "Asks: #{ob.asks}"
end

EM.run{
  con = WS.new
  con.connect(true)
  con.sub('order_book_btceur')
  con.bind('order_book_btceur', 'data') do |data|
    ob_updated(data)
  end
}