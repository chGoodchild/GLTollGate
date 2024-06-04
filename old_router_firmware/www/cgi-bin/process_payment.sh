#!/bin/sh
echo "Content-type: text/html"
echo ""
read -n $CONTENT_LENGTH POST_DATA
ecash=$(echo "$POST_DATA" | sed -n 's/^.*ecash=\([^&]*\).*$/\1/p' | sed 's/%20/ /g')
/bin/state_machine.sh "$ecash"
echo "<html><body><h1>Payment Processed</h1></body></html>"
