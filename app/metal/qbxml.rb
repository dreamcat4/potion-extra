
module Qbxml
  
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
      qbxml = <<-XML
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
    end

    if @done
      qbxml = ""
    end
    
    return qbxml
  end
  
  def self.receive_response(soap_envelope)
    resp = nil
    @error = false
    # puts xml.at("/soap:Envelope/soap:Body").first
    # (doc/'CustomerRet').each do |node|
    #   puts "Customer: #{node.innerText.strip}"
    # end
    # puts ::CGI::unescapeHTML soap_envelope.at("/soap:Envelope/soap:Body").first.to_s
    envelope_xml_raw = soap_envelope.at("/soap:Envelope/soap:Body").first.to_s
    envelope_xml = envelope_xml_raw.to_libxml_doc.root
    # xmlroot.register_default_namespace("soap")
    # puts "xxxxxxxxxxxxxxxx"
    # puts response_xml.to_s
    # puts response_xml.at("/receiveResponseXML/response").first
    # puts response_xml.at("/receiveResponseXML")
    envelope_xml.each do |node|
      if node.name == "response"
        resp_xml = ::CGI::unescapeHTML node.inner_xml
        resp = resp_xml.to_libxml_doc.root
      end
    end
    
    if resp.nil?
      @error = true
      @error_msg = "QBXML Failure: Couldn't parse xml."
    else
      # Process qbxml response
      puts "=="
      puts resp.to_s
      puts resp.at("/QBXML/QBXMLMsgsRs/CustomerQueryRs")
      if resp.name == ""
        customer = Customer.new(:qbxml => xml)
        customer.list_id # => "150000-933272658"
        customer.name # => "Abercrombie, Kristy"
        customer.bill_address_city # => "Bayshore"
      end
      puts "=="      
    end
    @done = true
  end
  
  # def error_msg
  #   return @error_msg
  # end
  
  def self.percent_done
    
    if error
      return -1
    end
    
    if @done
      return 100
    end
    
    return 0 # 0% Done, eg first request.
    # return (@n/num_requests*100).to_i
  end

end




