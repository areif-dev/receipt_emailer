import sys


def verify_argv(*args) -> bool:
    """
    Ensure that the program received proper command line args. The program should
    be called with 3 additional arguments: the path to a text file containing
    ABC invoice receipts to be converted to a PDF, the customer_id such as 
    "SMIJO 0", and the email address of the customer, such as "johnsmith@domain.com"

    :param args: A list containing the arguments to verify. This should most likely
    just be sys.argv
    :returns: Return True if the command line args are good. Return False otherwise
    """

    if len(args) < 4:
        print("Missing arguments. Expected to find \"module_name\" \"path/to/txt/file\" \"customer_id\" \"customer_email\"")
        return False
    else:
        try:
            with open(args[1], "r") as _:
                pass
        except FileNotFoundError: 
            print(f"The file, \"{args[1]}\" does not exist")
            return False
        except IsADirectoryError:
            print(f"The path $args[1] is a directory and cannot be read")
            return False
        finally:
            return True


def select_customer_invoices(invoices_str: str, customer_id: str):
    """
    Remove any invoice from invoices_str that was not rung out to customer_id
    
    :param invoices_str: The raw, unformatted string data from the ABC 3-13 report
    :param customer_id: The unique 6 character code that ABC assigns to each customer
    """

    invoice_lines = invoices_str.split("\n")
    
    index = len(invoice_lines)
    keep_invoice = False
    invoices_kept = []
    while index >= 0 and len(invoice_lines) > 0:
        index -= 1
        line = invoice_lines[index]

        # Generally, the customer id will appear around the 22nd line of the 
        # invoice. If the currect customer code is found, mark the invoice to be kept
        if line.strip().startswith(customer_id):
            keep_invoice = True

        # At this point, either the top of an invoice or a page break between a
        # multipage invoice has been found. If the word "continue" is in the line,
        # then keep going because this is a multipage invoice
        elif line.strip().startswith("INVOICE #") and "continued" not in line.lower():
            if keep_invoice:
                invoices_kept.append("\n".join(invoice_lines[index:]))
                keep_invoice = False

            del invoice_lines[index:]

    # Because the invoices were read backwards, this list is in order of most 
    # recent invoice first, oldest invoice last. 
    return invoices_kept[::-1]


def main():
    
    # Something is wrong with the command line args, so exit the program early
    if not verify_argv(*sys.argv):
        return

    invoices_file_path, customer_id, customer_email = sys.argv[1:4]

    with open(invoices_file_path, "r") as f:
        invoices_str = f.read()

    customer_invoices = select_customer_invoices(invoices_str, customer_id)
    for invoice in customer_invoices:
        print(invoice)
