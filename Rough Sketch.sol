//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Seller{

    constructor(){
        // make seller's adress as the owner
    }

    struct Invoice_Details { 
        uint invoiceNumber ;    
        address buyer_address;
        string productID;
        uint product_Price_inDollars;
        uint product_Quantity;
        uint total_Amount;
        string due_date;
        bool isInvoiceApproved;
        bool isInvoiceRejected;
        bool isPaymentDone;
    }

    Invoice_Details[] invoice;
    
    address[] Buyer_Addresses;

    modifier isSeller() {
        //to check if seller/owner is calling fuctions in this contract or not
        _;
    }

    function add_Buyer(address _buyer_address) external{
        Buyer_Addresses.push(_buyer_address);
        //also ensure that seller is not adding himself as a buyer to do fraud
    }

    function generateInvoice() external{
        //take arguments for struct Invoice_Details
        //isInvoiceApproved = false
        //isPaymentDone = false
    }

    function isInvoiceApproved() external{
        //take 'invoiceNumber' as argument and return value of 'isInvoiceApproved'
    }

    function isPaymentDone() external{
        //take invoiceNumber' as argument and return value of 'isPaymentdone'
    }

}

contract Buyer{
    
    modifier isBuyer() {
        //to check if buyer is calling fuctions in this contract or not
        _;
    } 

    function see_invoice_details() public view {
        // returns the details of the invoices according to the buyer's address
    }

    function approveInvoice() external {
        //require(!isInvoiceApproved && !isInvoiceRejected, "Invoice already approved or rejected");
        //isInvoiceApproved = true;
    }

    function rejectInvoice() external{
        
    }
}
