# Domain Validator Script (dvf.sh)

**!!! IMPORTANT WARNING !!!**

**This script performs HTTP requests to external websites. Running this script on a Virtual Private Server (VPS) or other cloud-based hosting environment might violate the terms of service of your hosting provider and lead to your VPS being flagged for abuse or even terminated. Excessive or automated web scraping can be considered malicious activity.  Only run this script on your local development machine or in a controlled environment where you have permission to perform such activities.**

This script, `dvf.sh`, validates certificate domains listed in a CSV file against their associated IP addresses and attempts to retrieve the HTML title from the domain.  It also handles cases where the domain might be accessible with or without the `www.` prefix, prioritizing the version with a valid title and providing HTTP status codes when no title is found.

## Prerequisites

*   **Bash:**  This script is written for Bash and requires a Bash environment to run.
*   **curl:**  The `curl` command is used to make HTTP requests to the domains to retrieve the HTML title.
*   **sed:** The `sed` command is used to parse the HTML and extract the title tag.
*   **dig:** The `dig` command is used to resolve domain names to IP addresses.
*   **CSV File:** The script expects a CSV file as input.  A sample CSV file (or a similar one) can be obtained from the [XTLS/RealiTLScanner](https://github.com/XTLS/RealiTLScanner) repository.

## Input CSV File Format

The CSV file should have the following format (comma-separated):

```
IP,ORIGIN,CERT_DOMAIN,CERT_ISSUER,GEO_CODE
103.135.249.4,103.135.249.0/24,*.y2y.io,"Let's Encrypt",HK
103.135.249.12,103.135.249.0/24,*.qujing.online,"ZeroSSL",HK
103.135.249.20,103.135.249.0/24,crmweb.app,"ZeroSSL",HK
```

*   **IP:** The IP address to validate against.
*   **ORIGIN:** The IP address range/origin.
*   **CERT_DOMAIN:** The certificate domain name to check.
*   **CERT_ISSUER:** The certificate issuer.
*   **GEO_CODE:** The geographical code.

**Note:** The script skips the header line in the CSV file.

## Usage

1.  **Download the Script:** Download the `dvf.sh` script.
2.  **Make it Executable:** Give the script execute permissions:

    ```bash
    chmod +x dvf.sh
    ```
3.  **Run the Script:** Execute the script, providing the path to the CSV file as an argument:

    ```bash
    ./dvf.sh your_csv_file.csv
    ```

    Replace `your_csv_file.csv` with the actual path to your CSV file.

4.  **Help Message:** To display the help message, use the `-h` option:

    ```bash
    ./dvf.sh -h
    ```

## Output

The script will output the results to the console, one line per domain in the CSV file. Each line will be formatted as follows:

```
https://<CERT_DOMAIN>, <IP>, PASS, <TITLE>
```

or if IP doesnt match

```
<CERT_DOMAIN>,FAIL,
```

*   **`https://<CERT_DOMAIN>`:** The certificate domain being checked (prepended with https://).
*   **`<IP>`:** The IP address being validated against.
*   **`PASS`:** Indicates that the domain resolves to the specified IP.
*   **`<TITLE>`:** The HTML title of the domain, enclosed in double quotes.

    *   If a title is found, it will be displayed.
    *   If no title is found but HTTP status codes are available for both `www.` and non-`www.` versions, the output will be `(<WWW_STATUS>/<NO_WWW_STATUS>)`, e.g., `(404/200)`. This indicates that `www.domain.com` returns status `404`, and domain.com returns status `200`.
    *   If the domain does NOT resolve to the specified IP, "FAIL" will be shown instead.

## Logic

The script performs the following steps for each line in the CSV:

1.  **DNS Resolution:** Resolves the `CERT_DOMAIN` to an IP address using `dig`.
2.  **IP Validation:** Checks if the resolved IP matches the `IP` from the CSV file.
3.  **Title Extraction:** If the IP validation passes, the script attempts to extract the HTML title from the domain:
    *   It first tries to fetch the title from `https://www.CERT_DOMAIN`.
    *   If that fails (no title tag or non-200 status code), it tries `https://CERT_DOMAIN`.
    *   If neither version returns a title, it outputs the HTTP status codes for both versions (if available).
4.  **Output:** Prints the result in the specified format.

## Error Handling

*   The script checks if the correct number of arguments is provided.
*   It checks if the CSV file exists.
*   If a domain does not have a title, it outputs HTTP status codes when available.
* If IP Address does not match, "FAIL" is printed in the output.

## Notes

*   The script prioritizes the `www.` version of the domain when fetching the title.  If both versions return a valid title, the `www.` version's title will be used.
*   The script discards the output of `curl` commands to reduce clutter in the console. Errors from `curl`, such as connection timeouts, will still be displayed. You can remove the `2>/dev/null` to debug and view all the curl output.
*   The script attempts to handle cases where a website might redirect from the bare domain to the `www.` subdomain or vice-versa.
*   This script uses the `https://` prefix, so make sure the script is connecting with https connections.
