<?php
include_once 'controller/MyOrdersController.php';

if (!isset($_SESSION['name'])) {
	header('location:index.php');
}

$c = new MyOrdersController;
return $c->getMyOrdersPage();
?>