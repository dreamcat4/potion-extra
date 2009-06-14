# require 'rubygems'
# require 'sinatra'
require 'hpricot'
require "libxml-bindings"
require 'fast_xs' # http server - "fast escaping" ?

# PE_PATH="#{RAILS_ROOT}/vendor/plugins/potion_extra"
set :views, "#{PE_PATH}/app/views/sinatra/qbwc_api"

class NilClass
  def fast_xs
    ''
  end
end
# im not been loaded! oh well
class QbwcApiController < ApplicationController
  layout "admin"
  before_filter :redirect_to_ssl

  def qbxml_xsd_file( region="A", version="8.0", \
                      dir="#{RAILS_ROOT}/vendor/plugins/potion_extra/app/views/xsd" )    
    # Please note: File names and locations may change in future
    
    # 1. Install QuickBooks SDK (requires Windows/PC environment)
    # http://www.consolibyte.com/wiki/doku.php/quickbooks_links
    
    # 2. Copy all the .xsd files from validator directory (17.4 MB)
    # C:/Program Files/Intuit/IDN/Common/tools/validator/
    # http://consolibyte.com/wiki/doku.php/quickbooks_qbxml
    # http://www.consolibyte.com/wiki/doku.php?id=quickbooks_example_qbxml
    
    # 3. Important files are:
    # QWC.xsd          - The schema for your .qwc configuration file
    # qbxmltypes80.xsd - Data types used by qbwc, such as BOOL and FLOAT
    # qbxml80.xsd      - The main qbwc xml soap schema ! 

    # You should use a regional variant (because of changes to AddCustomer, mainly)    
    # Valid regions are:
    # A = United States
    # C = Canada
    # U = United Kingdom
    # O = Online (not tested)
    # nil = Not region specific (not tested)
    
    version = version.to_f*10.to_i.to_s
    
    if (region)
      xsd_file = "QB#{region}qbxml#{version}.xsd"
    else
      xsd_file = "qbxml#{version}.xsd"
    end
    
    return dir+"/"+xsd_file
  end

  get '/qbwc/api' do
    erb :apiWelcome
  end

  post '/qbwc/api' do
    content_type 'text/xml'
    puts ""
    xml_str = request.body.read
    # My source document is:
    # <?xml version="1.0"?>
    # <document xmlns:test="http://www.test.org">
    # <test:foo>Element foo with namespace test</test:foo>
    # <document>
    
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

    puts ""
    puts "========== #{api_call}  =========="
    puts xml.at("/soap:Envelope/soap:Body").first
    puts "=="

    case api_call
    when 'serverVersion'
      erb :serverVersion
    when 'clientVersion'
      erb :clientVersion
    when 'authenticate'
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
        puts node.name
        puts "node.inner_xml"
        puts node.inner_xml
        
        if node.name == "strUserName"
          authenticated = false unless username == node.inner_xml
        end
        if node.name == "strPassword"
          authenticated = false unless password == node.inner_xml
        end
      end
            
      if(authenticated)
        puts "...authenticated"
        # @token = 'abc123'
        @token = username      
        # @message = ''
        @message = 'none'
        @seconds_until_next_update = "#{5}"
        @seconds_between_runs = "#{24*60*60}"
        puts "erb :authenticate"
        puts "#{erb :authenticate}"
        erb :authenticate
      else
        # content_type ''
        ""
        # erb :authenticate
        erb :connectionError
      end
      
    when 'sendRequestXML'
      @qbxml = <<-XML
  <?xml version="1.0" ?>
  <?qbxml version="5.0" ?>
  <QBXML>
    <QBXMLMsgsRq onError="continueOnError">
      <CustomerQueryRq requestID="1">
        <MaxReturned>10</MaxReturned>
        <IncludeRetElement>Name</IncludeRetElement>
      </CustomerQueryRq>
    </QBXMLMsgsRq>
  </QBXML>
  XML
      erb :sendRequestXML
    when 'receiveResponseXML'
      (doc/'CustomerRet').each do |node|
        puts "Customer: #{node.innerText.strip}"
      end
      @result = 100
      erb :receiveResponseXML
    when 'getLastError'
      @message = 'An error occurred'
      erb :getLastError
    when 'connectionError'
      @message = 'done'
      erb :connectionError
    when 'closeConnection'
      @message = 'OK'
      erb :closeConnection
    else
      ''
    end
    puts "=="
    
  end

  get '/qbwc/lorem' do
    # return "Home page - qbwc api"
    return "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  end

  get '/qbwc/api/error' do
    @message = 'An error occurred'
    puts "#{erb :getLastError}"
    erb :getLastError
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




