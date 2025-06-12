// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Get rid of strings inside custom errors
contract Store {
    uint256 ItemCount;

    error ValidPrice(string reason);
    error InvalidQuantity(string reason);
    error NotAvailable(string reason);
    error OutOfStock(string reason);
    error WrongAmount(string reason);
    error NotOwner(string reason);

    struct Item {
        address payable vendor;
        string name;
        uint256 price;
        uint128 quantity;
    }

    mapping(uint256 => Item) public items;

    event ItemAdded(uint256 indexed ID, address indexed vendor, string name, uint256 price, uint128 quantity);

    function AddItem(string memory _name, uint256 _price, uint128 _quantity) external {
        if (_price <= 0) revert ValidPrice("Price Can Not Be Zero");
        if (_quantity <= 0) revert InvalidQuantity("Quantity Can Not Be Zero");

        items[ItemCount] = Item({vendor: payable(msg.sender), name: _name, price: _price, quantity: _quantity});

        emit ItemAdded(ItemCount, msg.sender, _name, _price, _quantity);

        ItemCount++;
    }

    function PurchaseItem(uint256 ID, uint128 _quantity) external payable {
        if (ID >= ItemCount) revert NotAvailable("Item Not In Stock");
        if (_quantity <= 0) revert InvalidQuantity("Quantity Can Not Be Zero");

        Item storage item = items[ID];

        if (item.quantity < _quantity) revert OutOfStock("Not Enough In Stock");

        uint256 totalPrice = item.price * _quantity;
        if (msg.value != totalPrice) revert WrongAmount("Incorrect Amount To Pay");

        item.quantity -= _quantity;
        item.vendor.transfer(totalPrice);
    }

    function UpdateItemPrice(uint256 ID, uint256 _newPrice) external {
        if (ID >= ItemCount) revert NotAvailable("Item Not In Stock");
        if (_newPrice <= 0) revert ValidPrice("Price Can Not Be Zero");

        Item storage item = items[ID];

        if (item.vendor != msg.sender) revert NotOwner("You Are Not The Owner Of The Product");
        item.price = _newPrice;
    }

    function RestockItems(uint256 ID, uint128 _quantity) external {
        if (ID >= ItemCount) revert NotAvailable("Item Not In Stock");
        if (_quantity <= 0) revert InvalidQuantity("Quantity Can Not Be Zero");

        Item storage item = items[ID];
        if (item.vendor != msg.sender) revert NotOwner("You Are Not The Owner Of The Product");

        item.quantity += _quantity;
    }

    function ViewItem(uint256 ID) external view returns (Item memory) {
        if (ID >= ItemCount) revert NotAvailable("Item Not In Stock");

        return items[ID];
    }
}
