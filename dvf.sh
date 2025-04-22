#!/bin/bash

# Function to display help
show_help() {
  echo "Usage: $0 [-h] <csv_file>"
  echo "  -h: Display this help message"
  echo "  <csv_file>: Path to the CSV file to process"
  exit 0
}

# Check if the help option is given
if [[ "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# Check if the correct number of arguments is provided
if [[ $# -ne 1 ]]; then
  echo "Error: Incorrect number of arguments. CSV file must be provided." >&2
  show_help
  exit 1
fi

# Input CSV file (from command-line argument)
CSV_FILE="$1"

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file '$CSV_FILE' not found." >&2
  exit 1
fi

# Function to check if the certificate domain resolves to the given IP and grab the HTML title
check_domain() {
  local ip="$1"
  local domain="$2"
  local title=""
  local www_status="-"
  local nowww_status="-"

  # Resolve the domain name using dig and extract the IP address(es)
  RESOLVED_IP=$(dig +short "$domain" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')

  # Check if the resolved IP matches the given IP. Allow multiple resolved IPs.
  if [[ $(echo "$RESOLVED_IP" | grep "^$ip$") ]]; then

    # Function to fetch title, return code and title string
    get_title_and_status() {
      local url="$1"
      local status_code
      local title

      status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
      if [[ "$status_code" == "200" ]]; then
          title=$(curl -s "$url" | sed -n 's/<title>\(.*\)<\/title>/\1/p' 2>/dev/null)
      else
          title=""  # Consider it as no title if status code is not 200
      fi

      echo "$status_code,$title"
    }

    # Try the domain with "www." prefix first
    local result=$(get_title_and_status "https://www.$domain")
    www_status=$(echo "$result" | cut -d',' -f1)
    local WWW_TITLE=$(echo "$result" | cut -d',' -f2)

    # Try the domain without "www." if no title was found with "www."
    if [[ -z "$WWW_TITLE" ]]; then
        result=$(get_title_and_status "https://$domain")
        nowww_status=$(echo "$result" | cut -d',' -f1)
        local NO_WWW_TITLE=$(echo "$result" | cut -d',' -f2)

        if [[ -n "$NO_WWW_TITLE" ]]; then
            title="$NO_WWW_TITLE"
        else
            title="(${www_status}/${nowww_status})"  # Neither version has a title, show status codes
        fi
    else
        title="$WWW_TITLE"
    fi

    echo "https://$domain, $IP, PASS, $title"
    return 0  # Success
  else
    # echo "$domain,FAIL,"
    return 1  # Failure
  fi
}

# Read the CSV file line by line, skipping the header
tail -n +2 "$CSV_FILE" | while IFS=',' read -r IP ORIGIN CERT_DOMAIN CERT_ISSUER GEO_CODE; do
  # Call the check_domain function with the IP and certificate domain
  check_domain "$IP" "$CERT_DOMAIN"
done
