import unittest
import receipt_emailer
from datetime import datetime


class EmailerTestCase(unittest.TestCase):

    def test_verify_args(self):
        self.assertFalse(receipt_emailer.verify_argv())
        self.assertTrue(receipt_emailer.verify_argv("module", "receipt_emailer/tests/single_invoice.txt", "SMIJO 0", "john.smith@domain.com"))

    def test_select_customer_invoices(self):

        self.assertEqual(receipt_emailer.select_customer_invoices("", "SMIJO 0"), [])

        with open("receipt_emailer/tests/single_invoice.txt", "r") as f:
            single_invoice = f.read()

        self.assertEqual(len(receipt_emailer.select_customer_invoices(single_invoice, "SMIJO 0")), 1)

        with open("receipt_emailer/tests/multiple_invoices.txt", "r") as f:
            multiple_invoices = f.read()

        self.assertEqual(len(receipt_emailer.select_customer_invoices(multiple_invoices, "SMIJO 0")), 4)


    def test_fix_invoice_number(self):
        day_of_mill_invoice = datetime.strptime("12/31/13", "%m/%d/%y")
        day_before_invoice = datetime.strptime("12/30/13", "%m/%d/%y")
        day_after_invoice = datetime.strptime("1/1/14", "%m/%d/%y")

        self.assertEqual(receipt_emailer.fix_invoice_number("000000", day_of_mill_invoice), "1000000")
        self.assertEqual(receipt_emailer.fix_invoice_number("900000", day_of_mill_invoice), "900000")
        self.assertEqual(receipt_emailer.fix_invoice_number("900000", day_before_invoice), "900000")
        self.assertEqual(receipt_emailer.fix_invoice_number("900000", day_after_invoice), "1900000")

    
if __name__ == "__main__":
    unittest.main()
