// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {Store} from "../src/Market.sol";

contract TestMarketContract is Test {
    Store store;
    address vendor;
    address buyer;
    uint8 constant DECIMALS = 18;

    function setUp() public {
        store = new Store();
        vendor = address(0x123);
        buyer = address(0x124);

        vm.deal(vendor, 5 * (10 ** DECIMALS));
        vm.deal(buyer, 5 * (10 ** DECIMALS));
    }

    function testAddItem() public {
        vm.prank(vendor);
        store.AddItem("Shirt", 1 * (10 ** DECIMALS), 10);
        (address Vendor, string memory name, uint256 price, uint128 quantity) = store.items(0);

        assertEq(Vendor, vendor);
        assertEq(name, "Shirt");
        assertEq(price, 1 * (10 ** DECIMALS));
        assertEq(quantity, 10);
    }

    function testAddItemWithZeroPrice() public {
        vm.prank(vendor);
        vm.expectRevert(abi.encodeWithSelector(Store.ValidPrice.selector, "Price Can Not Be Zero"));
        store.AddItem("Cocaine", 0, 5);
    }

    function testPurchaseItem() public {
        vm.prank(vendor);
        store.AddItem("Shirt", 1 * (10 ** DECIMALS), 5);

        vm.prank(buyer);
        store.PurchaseItem{value: 2 * (10 ** DECIMALS)}(0, 2);

        (,,, uint128 quantityLeft) = store.items(0);
        assertEq(quantityLeft, 3);
    }

    function testPurchaseAllStock() public {
        vm.prank(vendor);
        store.AddItem("Shoes", 1 * (10 ** DECIMALS), 2);

        vm.prank(buyer);
        store.PurchaseItem{value: 2 * (10 ** DECIMALS)}(0, 2);

        (,,, uint128 quantityLeft) = store.items(0);
        assertEq(quantityLeft, 0);
    }

    function testPurchaseItemWithZeroQuantity() public {
        vm.prank(vendor);
        store.AddItem("Shirt", 1 * (10 ** DECIMALS), 5);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(Store.InvalidQuantity.selector, "Quantity Can Not Be Zero"));
        store.PurchaseItem{value: 1 * (10 ** DECIMALS)}(0, 0);
    }

    function testPurchaseMoreThanInStock() public {
        vm.prank(vendor);
        store.AddItem("Cap", 1 * (10 ** DECIMALS), 2);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(Store.OutOfStock.selector, "Not Enough In Stock"));
        store.PurchaseItem{value: 3 * (10 ** DECIMALS)}(0, 3);
    }

    function testUpdateItemPrice() public {
        vm.prank(vendor);
        store.AddItem("Shoes", 2 * (10 ** DECIMALS), 5);

        vm.prank(vendor);
        store.UpdateItemPrice(0, 3 * (10 ** DECIMALS));

        (,, uint256 price,) = store.items(0);
        assertEq(price, 3 * (10 ** DECIMALS));
    }

    function testUpdateItemPriceNotOwner() public {
        vm.prank(vendor);
        store.AddItem("Bag", 1 * (10 ** DECIMALS), 5);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(Store.NotOwner.selector, "You Are Not The Owner Of The Product"));
        store.UpdateItemPrice(0, 2 * (10 ** DECIMALS));
    }

    function testRestockItem() public {
        vm.prank(vendor);
        store.AddItem("Pen", 1 * (10 ** DECIMALS), 5);

        vm.prank(vendor);
        store.RestockItems(0, 10);

        (,,, uint128 quantity) = store.items(0);
        assertEq(quantity, 15);
    }

    function testRestockNotOwner() public {
        vm.prank(vendor);
        store.AddItem("Charger", 1 * (10 ** DECIMALS), 3);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(Store.NotOwner.selector, "You Are Not The Owner Of This Item"));
        store.RestockItems(0, 2);
    }
}
