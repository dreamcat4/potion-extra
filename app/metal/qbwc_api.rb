require "libxml-bindings"
require 'fast_xs'
require 'uuidtools'

require "qbxml"

# Don't throw exception on nil.fast_xs
class NilClass
  def fast_xs
    ''
  end
end

class QbwcApi < Sinatra::Application
  set :views, "#{PE_PATH}/app/views/qbwc"
  
  # layout "admin"
  # before_filter :redirect_to_ssl

  post '/qbwc/api' do
    content_type 'text/xml'
    puts "=="
    puts ""
    xml_str = request.body.read
    # puts xml_str

    # <?xml version="1.0" encoding="utf-8"?>
    # <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" \
    #                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  \
    #                xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    #   <soap:Body>
    #     <authenticate xmlns="http://developer.intuit.com/">
    #       <strUserName>bd3e861f6715e06dc9cd0e2c683e91b0</strUserName>
    #       <strPassword>any</strPassword>
    #     </authenticate>
    #   </soap:Body>
    # </soap:Envelope>
    
    xml = xml_str.to_libxml_doc.root
    # xmlroot.register_default_namespace("soap")
    req = xml.at("/soap:Envelope/soap:Body").first
    api_call = req.name

    # puts ""
    # puts "========== #{api_call}  =========="
    # puts xml.at("/soap:Envelope/soap:Body").first
    # puts "=="

    case api_call
    when 'serverVersion'
      # @version = "Server Version"
      # puts "#{erb :serverVersion}"
      return erb :serverVersion
    when 'clientVersion'
      # puts "#{erb :clientVersion}"
      return erb :clientVersion
    when 'authenticate'
      puts ""
      puts "========== #{api_call}  =========="
      # puts xml.at("/soap:Envelope/soap:Body").first
      puts "=="
      username = "bd3e861f6715e06dc9cd0e2c683e91b0" # echo "potion_extra" | md5
      password = "25984616630fa720601a9daffde01a3f" # echo "wordpass" | md5

      # puts req.at("/soap:strUserName")
      # puts req.at("soap:strUserName")
      # puts req.at("/strUserName")
      # puts req.at("/strPassword")
      # puts req.at("/http://developer.intuit.com/:strUserName")
      # puts req.at("/http://developer.intuit.com/:strPassword")
      # puts req["strUserName"]
      # puts req["strPassword"]
      
      # puts req.first.name
      # puts req.first.context
      # puts req.first.attributes
      # puts req.first.first
      # puts req.first.inner_xml

      # puts req.next
      
      # puts req.at("/strUserName")
      # puts req.at("strUserName")
      # Parse xml authenticate request, compare to username, password
      # puts "username: "+req.at("/soap:strUserName").to_s
      # puts "password: "+req.at("/soap:strPassword").to_s
      # puts "username: "+req.at("/soap:strUserName").inner_xml
      # puts "password: "+req.at("/soap:strPassword").inner_xml
      
      authenticated = true

      req.each do |node|
        # puts node.name
        # puts "node.inner_xml"
        # puts node.inner_xml
        
        if node.name == "strUserName"
          puts node.name
          puts node.inner_xml
          authenticated = false unless username == node.inner_xml
        end
        if node.name == "strPassword"
          puts node.name
          puts node.inner_xml
          authenticated = false unless password == node.inner_xml
        end
      end
      
      # @token = "{011e7e7f-5aa2-48f5-8cfc-7a1d28ac549c}"
      # @uuid = UUIDTools::UUID.random_create
      @uuid = UUIDTools::UUID.timestamp_create
      @token = @uuid.to_s
      
      if(authenticated)
        puts "...authenticated"
        
        if Qbxml::client_needs_update?
          # @rsp = "company_file" # Update specific named company file
          @rsp = ""      # Use current/open authorized company file 
        else
          @rsp = "none"  # No further response / no further action required
        end
        
      else
        puts "...not valid user"
        @rsp = "nvu"   # Not valid user
        # erb :connectionError
      end
      @seconds_until_next_update = "#{5}"
      # @seconds_between_runs = "#{24*60*60}"
      return erb :authenticate

    when 'sendRequestXML'
      @qbxml = Qbxml::next_request
      puts "========== #{api_call}  =========="
      # puts erb :sendRequestXML
      # puts "--"
      return erb :sendRequestXML
    when 'receiveResponseXML'
      puts ""
      puts "========== #{api_call}  =========="
      Qbxml::receive_response xml
      @result = Qbxml::percent_done
      return erb :receiveResponseXML
      
    # Error conditions & wrap-up
    when 'getLastError'
      # Show error message to user and end session
      @message = Qbxml::error_msg
      return erb :getLastError
    when 'connectionError'
      # Qbwc on client side couldnt' launch Quickbooks. End session.
      @message = 'done'
      return erb :connectionError
    when 'closeConnection'
      # End session
      @message = 'OK'
      return erb :closeConnection
    else
      content_type 'text/html'
      return erb :apiWelcome
    end
    
  end

  # We need a valid 'get' for qbwc client to download the SSL Server Certificate
  # Qbwc calls get only on the url "/qbwc/api", but include others here also 
  ["/qbwc/?", "/qbwc/api/?"].each do |path|
    get path do
      content_type 'text/html'
      return erb :apiWelcome
    end
  end

  # get '/qbwc/orders/:query' do
  get '/qbwc/orders' do
    # @message = 'Orders'
    
    # test_string = String.new()
    # test_string = "Hi! i am a string of artritrary length and size :)"
    # html = "#{test_string}<br>bytesize=#{test_string.bytesize}"
    # return html
    
    q = params[:query]
    conditions = "(status='C' OR status='X' OR status='F')"
    if q
      q = q.strip().downcase()
      if q.to_i != 0
        conditions = [conditions + "AND id=?", q.to_i]
        # @order = Order.find(q)
        # puts @order.to_xml
        # @message = @order.to_xml
        # return
      else
        conditions = [conditions + " AND (LOWER(email) LIKE ? OR
                                          LOWER(first_name) LIKE ? OR
                                          LOWER(last_name) LIKE ? OR
                                          LOWER(licensee_name) LIKE ?)", "#{q}%", "#{q}%", "#{q}%", "%#{q}%"]
      end
    end
    # @orders = Order.paginate :page => (params[:page] || 1), :per_page => 100, :conditions => conditions, :order => 'order_time DESC'
    # @orders = Order.paginate :page => 1
  end

  get '/qbwc/hello/:name' do
    # matches "GET /hello/foo" and "GET /hello/bar"
    # params[:name] is 'foo' or 'bar'
    "Hello #{params[:name]}!"
  end
  
  # GET /orders/1
  # GET /orders/1.xml
  get '/qbwc/order/:id' do
    @order = Order.find(params[:id])
    puts @order.to_xml
    # @message = @order

    # respond_to do |format|
    #   format.html # show.rhtml
    #   format.xml  { render :xml => @order.to_xml }
    # end
    @message = @order.to_xml
    
  end
  
  # post '/articles' do 
  #   article = Article.create! params 
  #   redirect "/articles/#{article.id}" 
  # end 
  
end




