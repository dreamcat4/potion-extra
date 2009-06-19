# Ok, busy trying to get it to work with WPS.
# 
# I'm trying to build it in a way that's least hacky possible. So we  
# could merge it back into trunk.
# 
# What I've got so far:
# 
# order_controller.rb line 85 (between the PayPal and GCheckout section)
# 
# ---

# Handle PayPal WPS orders
         elsif params[:payment_type] == 'paypal_wps'
             @order.payment_type = 'paypal_wps'
             @order.licensee_name = 'paypal_wps'
             @order.status = 'P'
             @order.save!
             render :action => 'payment_paypal_wps' and return

# ---

# I'm aware that this is probably not the best way of doing it, but it  
# looks like it's the only way. The order has to be saved to database  
# before we send it over to PayPal, and at this point, we don't know  
# licensee_name yet. So I just put in some dummy value because otherwise  
# it won't save. (I didn't think removing the validation for a licensee  
# name was a good idea). I also though that stats Pending was the best  
# status yet (Maybe we should just leave status out?). Unless of course  
# you decide to send licenses to pending payments.
# 
# Another problem with this is that the unfinished order stays in the  
# database even if the customer cancels (closes browser window) the  
# order at the confirm step.
# 
# Created a new view based off the gcheckout view:
# 
# payment_paypal_wps.rhtml

# ---

<h1>Confirm</h1>

<% unless @order.errors.empty? %>
<div id="errors">
   <h2 style="margin-bottom:14px;color:red">Problems</h2>
   <ul>
   <% @order.errors.each_full do |message| %>
     <li><%= message %></li>
   <% end %>
   </ul>
</div>
<% end %>

<p>Your license key, along with your purchase receipt, will be emailed to your PayPal email address.</p>

<div class="d cl"></div>

<div class="narrow">
        <% if @order.items_count == 1 %>
        <h2>Your Item</h2>
        <% else %>
        <h2>Your Items</h2>
        <% end %>

        <table id="order">
                <% for item in @order.line_items -%>
                <%   if item.quantity > 0 -%>
                <tr>
                        <td class="price"><%= item.quantity %> @ <%= number_to_currency item.unit_price %> each</td>
                        <td class="prod"><%= item.product.name %></td>
                </tr>
                <%   end -%>
                <% end -%>
                <% if @order.coupon -%>
                <tr>
                        <td class="price">-<%= number_to_currency(@order.coupon_amount) %></td>
                        <td><%= @order.coupon.description %></td>
                </tr>
                <% end -%>
                <tr id="total">
                        <td></td>
                        <td>Total: <strong><%= number_to_currency @order.total %></strong></td>
                </tr>
        </table>

</div>

<% if $STORE_PREFS['google_analytics_account'] != "" -%>
<script src="http://checkout.google.com/files/digital/urchin_post.js" type="text/javascript"></script>
<% end -%>

<%
   if $STORE_PREFS['google_analytics_account'] != ""
     form_onsubmit = "javascript:setUrchinInputCode();return validate();"
   else
     form_onsubmit = "javascript:return validate();"
   end
-%>

<div class="d"></div>

<p>
        <form action="https://www.paypal.com/cgi-bin/webscr" method="post" style="float:right;">
                <input type="hidden" name="cmd" value="_xclick">
                <input type="hidden" name="business" value="sa...@azuretalon.com">
                <input type="hidden" name="item_name" value="Azure Talon Software Purchase">
                <input type="hidden" name="item_number" value="<%= @order.id %>">
                <input type="hidden" name="amount" value="<%= @order.total %>">
                <input type="hidden" name="no_shipping" value="1">
                <input type="hidden" name="no_note" value="1">
                <input type="hidden" name="currency_code" value="EUR">
                <input type="hidden" name="bn" value="IC_Sample">
                <input type="hidden" name="return" value="http://store.azuretalon.com/store/order/thanks">
                <input type="hidden" name="notify_url" value="http://store.azuretalon.com/store/notification/paypal">
                <input type="submit" name="submit" value="Continue to PayPal">
        </form></p>

# ---

# In that last section, I hardcoded a few values, which should be  
# dynamically coded if this was merged back (and I case I change domain  
# or something, who knows)
# 
# Edited a section in new.rhtml:

# ---
                        <% if false then -%>
                        <p class="creditcards">
                                <%= radio_button_tag 'payment_type', 'cc', !(['paypal',  'gcheckout'].member? @payment_type), :id => 'creditcard' %>
                                <img src="/images/store/visa.gif" alt="Visa" /><img src="/images/store/mc.gif" alt="MasterCard" /><img src="/images/store/amex.gif"  alt="Amex" /><img src="/images/store/discover.gif" alt="Discover" />
                        </p>
                        <p class="paypal" style="font: 10px helvetica">
                                <%= radio_button_tag 'payment_type', 'paypal', @payment_type ==  'paypal', :id => 'paypal' %>
                                <img src="/images/store/paypal.gif" alt="PayPal" />
                                Shop without sharing your financial information
                        </p>
                        <% end -%>
                        <p class="paypal" style="font: 10px helvetica">
                                <%= radio_button_tag 'payment_type', 'paypal_wps', true, :id =>  'paypal_wps' %>
                                <img src="/images/store/paypal.gif" alt="PayPal" />
                                Shop without sharing your financial information
                        </p>
                        <% if $STORE_PREFS['allow_google_checkout'] then -%>
                        <p class="gcheckout">
                                <%= radio_button_tag 'payment_type', 'gcheckout', @payment_type ==  'gcheckout', :id => 'gcheckout' %>
                                <img src="/images/store/gcheckout.gif" alt="Google Checkout" />
                        </p>
                        <% end -%>
# ---

# the 'if false then' are just a way of commenting standard paypal out
# the third argument to radio_button_tag is true, because that's the  
# only option on my personal store, but if merged back, i think it  
# should be @payment_type == 'paypal_wps'
# 
# order.rb (the model)

# ---

   def paypal_wps?
       return self.payment_type != nil && self.payment_type.downcase  == 'paypal_wps'
   end

# ---

# don't think it's actually required, but I put it in there anyway.
# 
# and lastly, not quite finished with that, but here's the gist of it:  
# PayPal IPN.
# 
# notification_controller.rb

# ---

   ## Handeling PayPal IPN

     def paypal
        if @request.method == :post
          # use the POSTed information to create a call back URL to  PayPal
          @query = 'cmd=_notify-validate'
          @request.params.each_pair {|key, value| @query = @query +  '&' + key + '=' + value.first if key != 'register/pay_pal_ipn.html/pay_pal_ipn' }

        #POST this data
          http = Net::HTTP.start(PAYPAL_URL, 80)
          response = http.post('/cgi-bin/webscr', @query)
          http.finish

   # PayPal values
          item_name = @params[:item_name]
          item_number = @params[:item_number]
          payment_status = @params[:payment_status]
          payment_amount = @params[:mc_gross]
          payment_currency = @params[:mc_currency]
          txn_id = @params[:txn_id]
          receiver_email = @params[:receiver_email]
          payer_email = @params[:payer_email]
          if response
             if response.body.chomp  'VERIFIED'
                # check the payment status
                if payment_status  'Completed'
                   # should check to see if the txn_id already exists

                    order = Order.find(item_number)
                    order.first_name = @params[:first_name]
                    order.last_name = @params[:last_name]

                    order.email = payer_email
                    if order.email == nil # This shouldn't happen, but  just in case
                      order.status = 'F'
                      order.failure_reason = 'Did not get email from  PayPal'
                      order.finish_and_save()
                      return
                    end

                    order.address1 = @params[:address_street]
                    order.address2 = ''
                    order.city     = @params[:address_city]
                    order.company  = @params[:payer_business_name]
#                   order.country  = @params[:address_country_code]
                    order.zipcode  = @params[:address_zip]
#                   order.state    = @params[:address_state]

                    order.transaction_number = txn_id

                    order.status = 'C'

                    order.finish_and_save()
                    OrderMailer.deliver_thankyou(order) if is_live()

                end

             end
          end
        else
           # GET request, wtf
           @text = 'I do not speak GET'
        end
     rescue Net::HTTPError
        @text = 'HTTP error'
     end

# ---

# all i got for now... I hope I'm getting somewhere here
# 
# ---
# Kenneth Ballenegger
# www.seoxys.com
# seo...@gmail.com
# 
# Azure Talon Software
# www.azuretalon.com
# supp...@azuretalon.com
# 
# Exces
# www.excesapp.com

