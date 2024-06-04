#!/bin/bash

# Log the payment attempt
echo "Payment received: tok=$1 redir=$2 ecash=$3" >> /var/log/payment.log

# Simulate connecting the user to the internet
echo "User connected to the internet"

# Redirect to the success page or the desired redirect URL
echo "Content-type: text/html"
echo ""
echo "<html><body><h1>Payment Successful!</h1></body></html>"
