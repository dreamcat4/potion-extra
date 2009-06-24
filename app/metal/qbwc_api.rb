require "libxml-bindings"
require 'fast_xs'
require 'uuidtools'

# Don't throw exception on nil.fast_xs
class NilClass
  def fast_xs
    ''
  end
end

class QbwcApi < Sinatra::Application

  set :views, "#{PE_PATH}/app/views/qbwc"

  layout "admin"
  # before_filter :redirect_to_ssl

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
    content_type 'text/html'
    erb :apiWelcome
  end

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
      
      @uuid = UUIDTools::UUID.timestamp_create
      # @uuid = UUIDTools::UUID.random_create
      @token = @uuid.to_s
      
      # @token = "{011e7e7f-5aa2-48f5-8cfc-7a1d28ac549c}"
      if(authenticated)
        puts "...authenticated"        
        @rsp = ""      # Use current company file
        # @rsp = "company_file" # Use this named company file
        # @rsp = "none"  # No further response / no further action required
      else
        puts "...not valid user"
        @rsp = "nvu"   # Not valid user
        # erb :connectionError
      end
      @seconds_until_next_update = "#{5}"
      @seconds_between_runs = "#{24*60*60}"
      # puts "erb :authenticate"
      # puts "#{erb :authenticate}"
      return erb :authenticate

      # Loop
      # If the return from sendRequestXML is an empty string, QBWC stops the update and calls
      # closeConnection. Otherwise, it passes the supplied string to the QuickBooks request processor to be
      # handled. The string must be a valid qbXML request message.
      
       # The data returned by Quickbooks in response to the incoming requests is supplied in the QBWC
      # receiveResponseXML, in the response parameter. Your callback returns a negative integer if there
      # are any errors, such as out of sequence calls due to network problems. Otherwise, it returns a
      # positive integer between 0 and 100, indicating the percentage of work done up to that point, with a
      # value of 100 meaning that the update activity is finished. If there is work left, then QBWC calls
      # sendRequestXML again to allow your web service to continue its work.
      
       # If the return from receiveResponseXML is a negative integer, QBWC calls getLastError to allow
      # your web service to supply some message string to inform the user. This message is displayed by
      # QBWC and then QBWC invokes closeConnection to end the session.

    when 'sendRequestXML'
#       @qbxml = <<-XML
# <?xml version="1.0" ?>
# <?qbxml version="5.0" ?>
#   <QBXML>
#     <QBXMLMsgsRq onError="continueOnError">
#       <CustomerQueryRq requestID="1">
#         <MaxReturned>10</MaxReturned>
#         <IncludeRetElement>Name</IncludeRetElement>
#       </CustomerQueryRq>
#     </QBXMLMsgsRq>
#   </QBXML>
#   XML
      @qbxml = <<-XML
<?xml version="1.0" ?>
<?qbxml version="6.0"?>
  <QBXML>
    <QBXMLMsgsRq onError = "continueOnError">
      <CustomerQueryRq requestID = "0">
        <MaxReturned>10</MaxReturned>
      </CustomerQueryRq>
    </QBXMLMsgsRq>
  </QBXML>  
XML
#       @qbxml = <<-XML
# <?xml version="1.0" ?>
# <?qbxml version="6.0"?>
#   <QBXML>
#     <QBXMLMsgsRq onError = "continueOnError">
#       <CustomerQueryRq requestID = "0">
#         <MaxReturned>10</MaxReturned>
#         <ActiveStatus>ActiveOnly</ActiveStatus>
#       </CustomerQueryRq>
#     </QBXMLMsgsRq>
#   </QBXML>  
# XML
      # puts "erb :sendRequestXML--"
      # puts erb :sendRequestXML
      # puts "--"
      return erb :sendRequestXML
    when 'receiveResponseXML'
      puts ""
      puts "========== #{api_call}  =========="
      # puts xml.at("/soap:Envelope/soap:Body").first
      # (doc/'CustomerRet').each do |node|
      #   puts "Customer: #{node.innerText.strip}"
      # end
      # puts ::CGI::unescapeHTML xml.at("/soap:Envelope/soap:Body").first.to_s
      response_xml_raw = xml.at("/soap:Envelope/soap:Body").first.to_s
      response_xml = response_xml_raw.to_libxml_doc.root
      # xmlroot.register_default_namespace("soap")
      # puts "xxxxxxxxxxxxxxxx"
      # puts response_xml.to_s
      # puts response_xml.at("/receiveResponseXML/response").first
      # puts response_xml.at("/receiveResponseXML")
      req = response_xml
      req.each do |node|
        # puts "node.inner_xml"
        # puts node.inner_xml
        
        if node.name == "response"
          # puts node.name
          puts "=="
          puts ::CGI::unescapeHTML node.inner_xml
        end
      end
      puts "=="
      @result = 100
      return erb :receiveResponseXML
    when 'getLastError'
      @message = 'An error occurred'
      return erb :getLastError
    when 'connectionError'
      @message = 'done'
      return erb :connectionError
    when 'closeConnection'
      @message = 'OK'
      return erb :closeConnection
    else
      ''
    end
    
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




