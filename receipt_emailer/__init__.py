import sys
from reportlab.pdfgen.canvas import Canvas
from reportlab.lib.units import mm, inch


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

        # At this point, the loop has either reached the beginning of the invoice
        # or a page break between a multipage invoice. If the word "continue" is 
        # in the line, then the page is part of a long invoice, and nothing should
        # be done yet. Otherwise, it is the start of an invoice, so break that 
        # invoice out
        elif line.strip().startswith("INVOICE #") and not "continue" in line.lower():
            if keep_invoice:
                invoices_kept.append("\n".join(invoice_lines[index:]))
                keep_invoice = False

            del invoice_lines[index:]

    # Because the invoices were read backwards, this list is in order of most 
    # recent invoice first, oldest invoice last. 
    return invoices_kept[::-1]


def txt_to_pdf(invoices: list[str], output: str):
    """
    Convert a list of plaintext invoices from an ABC 3-13 report into a PDF. 
    This should generally be called on the output of select_customer_invoices

    :param invoices: A list where each item is a complete invoice from ABC
    :param output: The path where the output PDF file should be saved
    """

    canvas = Canvas(output, (8.5 * inch, 11 * inch))
    canvas.setFont("Courier", 12)

    # The default top of the page. Horizontal, Vertical
    START_POS = (5 * mm, 11 * inch - 10 * mm)
    
    for invoice in invoices:
        hori_pos, vert_pos = START_POS

        for line in invoice.split("\n"):

            # Encountered a page break on a multipage invoice. Each page of the
            # invoice should have its own page in the PDF, so start a new page
            if line.strip().startswith("INVOICE #") and "(Continued)" in line:
                canvas.showPage()
                canvas.setFont("Courier", 12)
                hori_pos, vert_pos = START_POS

            canvas.drawString(hori_pos, vert_pos, line)
            vert_pos -= 4 * mm

        canvas.showPage()
        canvas.setFont("Courier", 12)

    canvas.save()


def main():
    
    # Something is wrong with the command line args, so exit the program early
    if not verify_argv(*sys.argv):
        return

    invoices_file_path, customer_id, customer_email = sys.argv[1:4]

    with open(invoices_file_path, "r") as f:
        invoices_str = f.read()

    customer_invoices = select_customer_invoices(invoices_str, customer_id)
    txt_to_pdf(customer_invoices, "test.pdf")
