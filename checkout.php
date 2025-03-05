<?php
include_once "controller/CheckoutController.php";

if (!isset($_SESSION['name']) || !isset($_SESSION['cart'])) {
	header('location:index.php');
}

$c = new CheckoutController;
if (isset($_POST['btnCheckout'])) {
    return $c->checkOut();
}

return $c->loadCheckoutPage();
?>