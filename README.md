# receipt_emailer
Scripts to automate the process of emailing receipts to customers from the ABC accounting software

## Installing 

### Dependencies

- Python 3.7+: https://python.org

### Git Clone

Clone this repository to a folder you will remember

```bash
git clone https://github.com/areif-dev/receipt_emailer
```

### Manual Download

If you do not have git installed, you can also download the necessary code from GitHub directly by going to https://github.com/areif-dev/receipt_emailer, clicking the "Code" button, then "Download Zip". Then just unzip the downloaded archive to a location that you will remember. 

| Open "Code" menu from https://github.com/areif-dev/receipt_emailer |
| :----------------------------------------------------------------: |
|       ![click_the_code_button](/screenshots/github_01.png)         |

| Click "Download Zip" button in the "Code" menu |
| :--------------------------------------------: |
| ![click_the_download_button](/screenshots/github_02.png) | 

## Usage

- Start the script called `receipt_emailer.ahk`, which should be stored in the directory you unpacked this repository to
- A small form will open asking for a starting invoice, last invoice, a customer ID, and the customer email
  - Starting Invoice: Required. The ID of the first invoice to try emailing to the customer
  - Last Invoice: Optional. The ID of the last invoice to try emailing to the customer. If this is left blank, then Last Invoice is assumed to be the same as Starting Invoice
  - Customer ID: Optional. The ID of the customer to select to send invoices to. If this is left blank, then Customer ID is assumed to be the ID of the customer from Starting Invoice
  - Customer Email: Optional. The email address to send the invoices to. If this is left blank, then the email address from the customer file of Customer ID will be used

| Example Receipt Emailer Form |
| :--------------------------: |
| ![example_receipt_emailer_run](/screenshots/receipt_emailer_example.png) |

- That is all the manual input that is required. The script will take over and navigate through various ABC screens, generate the invoice reports, then email the customer
  - *_Do not touch the mouse or keyboard while the script is running!_* This may cause the script to fail.
