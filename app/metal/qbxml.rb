
module Qbxml
  @request_id = 0
  def self.client_needs_update?
    return true
  end
  
  def self.next_request
    @done = false
    
    # Pre-state checks
    #   find last reconciled tn
    #   Any new #tn's ? => yes ?
    #     => query quickbooks
    #          # "What was your last reconciled transaction?"
    #          # "Never?" => Goto Populate accounts / initialization routine
    #          #  "Last reconcile was Date XX-XX-XX" => Upload new transactions / Fast-forward / tn update routine  

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
    if !@done
      case @request_id
      when 0
        qbxml = <<-XML
<?xml version="1.0" ?>
<?qbxml version="6.0"?>
          <QBXML>
            <QBXMLMsgsRq onError = "continueOnError">
              <CustomerQueryRq requestID = "#{@request_id}">
                <MaxReturned>10</MaxReturned>
              </CustomerQueryRq>
            </QBXMLMsgsRq>
          </QBXML>  
        XML
        puts qbxml
      when 1
        puts "=="
        # <EditSequence>1</EditSequence>
        customer_mod = @customer.to_qbxml
        puts customer_mod
        cm_doc = customer_mod.to_xmldoc
        node = cm_doc.at("/Customer")
        node.name = node.name + "Mod"

        node = cm_doc.at("/CustomerMod/EditSequence")
        if node.nil?
          node = cm_doc.at("/CustomerMod")          
          child = XML::Node.new("EditSequence", "1")
          node << child
        else
          # node.content = (node.content.to_i+1).to_s
        end
        node = cm_doc.at("/CustomerMod/Name")
        # node.content = "Old MacDonald Trump"
        # node.content = "Old MacDonald"
        node.content = "Ivana Trump"
        # customer_mod = cm_doc.to_xml.squeeze! " "
        node = cm_doc.at("/CustomerMod/TimeCreated")
        node.remove!
        node = cm_doc.at("/CustomerMod/TimeModified")
        node.remove!
        node = cm_doc.at("/CustomerMod/Balance")
        node.remove!
        node = cm_doc.at("/CustomerMod/TotalBalance")
        node.remove!
        node = cm_doc.at("/CustomerMod/SalesTaxCountry")
        node.remove!
        node = cm_doc.at("/CustomerMod/JobStatus")
        node.remove!
        node = cm_doc.at("/CustomerMod/Sublevel")
        node.remove!
        node = cm_doc.at("/CustomerMod/FullName")
        node.remove!
        node = cm_doc.at("/CustomerMod/BillAddressBlock")
        node.remove!
        # node = cm_doc.at("/CustomerMod/")
        # node.remove!
        
        customer_mod = cm_doc.to_xml
        qbxml = <<-XML
<?xml version="1.0" ?>
<?qbxml version="6.0"?>
                  <QBXML>
                    <QBXMLMsgsRq onError = "continueOnError">
                      <CustomerModRq requestID = "#{@request_id}">
                      #{customer_mod}
                      </CustomerModRq>
                    </QBXMLMsgsRq>
                  </QBXML>  
        XML
#         qbxml = <<-XML
# <?xml version="1.0" ?>
# <?qbxml version="6.0"?>
#           <QBXML>
#             <QBXMLMsgsRq onError = "continueOnError">
#               <CustomerModRq requestID = "1">
#               <CustomerMod>
#               <ListID>80000002-1245792458</ListID>
#               <EditSequence>1246918347</EditSequence>
#               <Name>Old MacDonald</Name>
# </CustomerMod>
#               </CustomerModRq>
#             </QBXMLMsgsRq>
#           </QBXML>
#         XML
        puts "=="
        
        # delete leading whitespace (spaces/tabs/etc) from beginning of each line
        # gsub(/^\s+/, "")
        
        # delete BOTH leading and trailing whitespace from each line
        qbxml = qbxml.gsub(/^\s+/, "").gsub(/\s+$/, $/)
        
        
        puts qbxml
        puts "=="
        
      end

    end

    if @done
      qbxml = ""
    end
    
    @request_id += 1
    return qbxml
  end
  
  def self.receive_response(soap_envelope)
    # puts "======soap_envelope======"
    # puts soap_envelope.to_s
    # puts "=="
    resp = nil
    @error = false
    # puts xml.at("/soap:Envelope/soap:Body").first
    # (doc/'CustomerRet').each do |node|
    #   puts "Customer: #{node.innerText.strip}"
    # end
    # puts ::CGI::unescapeHTML soap_envelope.at("/soap:Envelope/soap:Body").first.to_s

    envelope_xml_raw = soap_envelope.at("/soap:Envelope/soap:Body").first.to_s
    envelope_xml = envelope_xml_raw.to_libxml_doc.strip!.root
    # xmlroot.register_default_namespace("soap")
    # puts "xxxxxxxxxxxxxxxx"
    # puts response_xml.to_s
    # puts response_xml.at("/receiveResponseXML/response").first
    # puts response_xml.at("/receiveResponseXML")
    
    # <receiveResponseXML xmlns="http://developer.intuit.com/">
    #   <ticket>1093812e-6a53-11de-95f2-0016cbfffe58</ticket>
    #   <response/>
    #   <hresult>0x80040400</hresult>
    #   <message>QuickBooks found an error when parsing the provided XML text stream.</message>
    # </receiveResponseXML>
    
    
    envelope_xml.each do |node|
      puts "node_name=#{node.name}"

      if node.name == "response"
        if node.inner_xml.class == String && node.inner_xml.length > 0
        # if node.inner_xml
          puts node.inner_xml+"\\n"
          puts node.inner_xml.class
          resp_xml = ::CGI::unescapeHTML node.inner_xml
          resp = resp_xml.to_libxml_doc.root
        end
      end
      if node.name == "message"
        puts node.inner_xml
      end
    end
    
    if resp.nil?
      @error = true
      @error_msg = "QBXML Failure: Couldn't parse xml."
    else
      resp_request_id = nil
      # Process qbxml response
      puts "=="
      # puts resp.to_s
      # puts resp.at("/QBXML/QBXMLMsgsRs/CustomerQueryRs")

      # puts resp.to_s
      resp.at("/QBXML/QBXMLMsgsRs").each do |node|
        if node.name =~ /.*Rs/ # When node = "CustomerQueryRs", && !text
          puts node
          resp_request_id = node.attributes["requestID"].to_i
          # puts "node_name=#{node.name}"
          # puts "resp_request_id = #{resp_request_id}"
        end
      end
      # puts "resp_request_id = #{resp_request_id}"
      case resp_request_id
        when 0
          # puts "resp_request_id = #{resp_request_id}"
          @percent = 50
          return self.customer_query_rs resp 
        
        when 1
          @done = true
          return self.customer_mod_rs resp
        else
          @done = true
        end
        
      puts "=="      
    end
    # @done = true
  end
  
  # def error_msg
  #   return @error_msg
  # end
  
  def self.customer_query_rs(resp)
    customer_xml = nil
    
    puts "self.customer_query_rs"
    
    resp.at("/QBXML/QBXMLMsgsRs/CustomerQueryRs").each do |node|
      puts "node=#{node.name}"
      if node.name == "CustomerRet"
        customer_xml = node
      end
    end
    
    if customer_xml
      puts "=="
      # puts customer_xml
      @customer = Customer.new(:qbxml => resp.at("/QBXML/QBXMLMsgsRs/CustomerQueryRs/CustomerRet").to_s)
      puts "=="
      # More than 41 characters -------------890
      @customer.name = "More than 41 characters -------------8901---------------------------------------XYZ"
      @customer.balance = 98765432109876543.94
      @customer.total_balance = 9.23489723984723
      # puts @customer.errors.full_messages
      unless @customer.valid?
        @customer.errors.each_full do |error|
          puts error
        end
      end
      puts @customer.list_id # => "150000-933272658"
      puts @customer.name # => "Abercrombie, Kristy"
      # puts customer.bill_address_city # => "Bayshore"
      
      # Readme Example
      # kristy = Customer.new()
      # kristy.list_id = "150000-933272658"
      # kristy.name = "Abercrombie, Kristy"
      # kristy.bill_address_addr1 = "4544 Hillard Way"
      # kristy.bill_address_addr2 = ""
      # kristy.bill_address_city = "Grand Island"
      # kristy.bill_address_state = "NE"
      # kristy.bill_address_postal_code = "68801"
      # puts kristy.to_qbxml
      
      puts "=="
      # puts @customer.to_qbxml
      return 
    end
    
  end
  
  def self.customer_mod_rs(resp)
    
  end
  
  def self.percent_done
    
    if @error_msg
      return -1
    end
    
    if @done
      return 100
    end
    
    return @percent unless @percent.nil?
    
    return 0 # 0% Done, eg first request.
    # return (@n/num_requests*100).to_i
  end

  def self.error_msg
    return @error_msg
  end

end




