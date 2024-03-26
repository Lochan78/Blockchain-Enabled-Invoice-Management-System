//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract InvoiceReconciliation{

    address payable private supplier;
    
    constructor(){
        supplier = payable(msg.sender);
    }

    modifier onlySupplier() {
        //to check if seller/owner is calling fuctions in this contract or not
        require(msg.sender == supplier, "Not owner!");
        _;
    }
    modifier checkSender() {
        require(msg.sender == supplier || customersMap[msg.sender], "Not owner!");
        _;
    }
    modifier onlyCustomers() {
        require(customersMap[msg.sender], "Not a certified customer!");
        _;
    }

    mapping(address=>bool) public customersMap;

    function addCustomer(address _customerAddress) onlySupplier external  {
        require(_customerAddress != supplier, "Buyer cannot be Supplier");
        require(customersMap[_customerAddress] != true, "Already a customer");
        customersMap[_customerAddress] = true;
    }

    mapping(uint=>uint) public productId_toAmount;
    function addProduct(uint _productId, uint _amount) external onlySupplier{
        productId_toAmount[_productId] = _amount;

    }
    function removeProduct(uint _productId) external onlySupplier{
        delete productId_toAmount[_productId];

    }

    struct PurchaseOrderRequest{
        uint purchaseOrderId;
        address custAddress;
        uint productID;
        uint productQuantity;
        uint minProductQuantity;
        bool seenBySeller;
        PurchaseOrderStatus status;
    }

    enum PurchaseOrderStatus { Pending, Accepted, Rejected }
    
    uint private orderId = 0;
    uint private shipID = 0;
    uint private invoice_ID = 0;
    //PurchaseOrderRequest[] purchase_order_requests;

    mapping (uint=>PurchaseOrderRequest) private purchaseOrderRequest_Map;
    mapping (uint=>AdvanceShipmentNotification) private ASN_Map;
    mapping (uint=>InvoiceDetails) private Invoice_Map;

    function makePurchaseOrderRequests(uint _productId,uint _productquantity,uint _minproductquantity) public onlyCustomers returns(uint){
        orderId++;

        require(productId_toAmount[_productId] != 0, "Product does not exist!");
        purchaseOrderRequest_Map[orderId]=PurchaseOrderRequest(orderId,msg.sender, _productId,_productquantity,_minproductquantity,false,PurchaseOrderStatus.Pending);
        //emit OrderMade(orderId);
        return orderId;    
    }

    modifier notAlreadyProcessed(uint _purchaseOrderID) {
        require(purchaseOrderRequest_Map[_purchaseOrderID].status == PurchaseOrderStatus.Pending, "Purchase order already processed");
        _;
    }

    modifier notSeenBySeller(uint _purchaseOrderID) {
        require(!purchaseOrderRequest_Map[_purchaseOrderID].seenBySeller, "Purchase order already seen by seller");
        _;
    }

    function PROCESS_UPDATE(uint _purchaseOrderID, bool _accept) external onlySupplier notAlreadyProcessed(_purchaseOrderID) notSeenBySeller(_purchaseOrderID) {
        if (_accept) {
            purchaseOrderRequest_Map[_purchaseOrderID].status = PurchaseOrderStatus.Accepted;
        } else {
            purchaseOrderRequest_Map[_purchaseOrderID].status = PurchaseOrderStatus.Rejected;
        }

        purchaseOrderRequest_Map[_purchaseOrderID].seenBySeller = true;
    }

    function getPurchaseOrderRequest(uint _purchaseOrderId) public view  checkSender returns(PurchaseOrderRequest memory){
        require( purchaseOrderRequest_Map[_purchaseOrderId].custAddress == msg.sender || msg.sender== supplier, "You are not authorized to view the purchase order ID");
        return purchaseOrderRequest_Map[_purchaseOrderId];
    }

    struct AdvanceShipmentNotification{
        uint shipmentId;
        uint purchaseOrderID;
        uint qty;
        bool isShipMentReceived;
    }

    function sendASN(uint _purchaseOrderID,uint _qty) external onlySupplier returns(bool) {
        require(_qty >= purchaseOrderRequest_Map[_purchaseOrderID].minProductQuantity , "Quantity should be greater than minimum product quantity.");
        shipID++;
        ASN_Map[_purchaseOrderID] = AdvanceShipmentNotification(shipID,_purchaseOrderID,_qty,false);
        return true;
        //require whether purchase order ID is valid or not
    }

    function getASN(uint _purchaseOrderID) public view checkSender returns(AdvanceShipmentNotification memory) {
        require( purchaseOrderRequest_Map[_purchaseOrderID].custAddress == msg.sender || msg.sender== supplier, "You are not authorized to view the purchase order ID");
        return ASN_Map[_purchaseOrderID];
    }

    function shipmentRececeived(uint _purchaseOrderID) external onlyCustomers{
        require( purchaseOrderRequest_Map[_purchaseOrderID].custAddress == msg.sender, "You are not authorized to view the purchase order ID");
       
        ASN_Map[_purchaseOrderID].isShipMentReceived = true;
    } 

    struct InvoiceDetails{
        uint invoiceID;
        uint purchaseOrderID;
        address payable seller;
        address custAddress;
        uint productID;
        uint productQty;
        uint totalAmount;
        uint due_date;
        bool isPaid;
    }

    function makeInvoice(uint _purchaseOrderID,uint _totalamount,uint _duedate) external onlySupplier returns(uint){
        require( ASN_Map[_purchaseOrderID].isShipMentReceived == true , "Shipment NOT received yet.");
        invoice_ID++;
        Invoice_Map[invoice_ID] = InvoiceDetails(invoice_ID,
                                                _purchaseOrderID,
                                                supplier,
                                                purchaseOrderRequest_Map[_purchaseOrderID].custAddress,
                                                purchaseOrderRequest_Map[_purchaseOrderID].productID,
                                                ASN_Map[_purchaseOrderID].qty,
                                                _totalamount,
                                                _duedate,
                                                false);
        return invoice_ID;
    }

    function getInvoice(uint _invoiceID) public checkSender view returns(InvoiceDetails memory) {
        uint _purchaseOrderId = Invoice_Map[_invoiceID].purchaseOrderID;
        require( purchaseOrderRequest_Map[_purchaseOrderId].custAddress == msg.sender || msg.sender== supplier, "You are not authorized to view the purchase order ID");
        return Invoice_Map[_invoiceID];
    }

    function PAY_INVOICE(uint256 invoiceId) onlyCustomers external payable {
        require(Invoice_Map[invoiceId].custAddress == msg.sender, "You are not authorized to pay the invoice");
        require(Invoice_Map[invoiceId].seller != address(0), "Invoice does not exist");
        require(!Invoice_Map[invoiceId].isPaid, "Invoice already paid");
        require(msg.value == Invoice_Map[invoiceId].totalAmount, "Incorrect payment amount");

        Invoice_Map[invoiceId].isPaid = true;
        Invoice_Map[invoiceId].seller.transfer(msg.value);
        
        }
}