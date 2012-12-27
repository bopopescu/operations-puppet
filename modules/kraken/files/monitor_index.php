<?php
# Note: This file is managed by Puppet.


$image_width = $_REQUEST['image_width'] ? htmlspecialchars($_REQUEST['image_width']) : "600px";
$columns     = $_REQUEST['columns'] ? htmlspecialchars($_REQUEST['columns']) : 2;
$period      = $_REQUEST['period'] ? htmlspecialchars($_REQUEST['period'])   : "4hr";
$legend      = $_REQUEST['legend'] ? htmlspecialchars($_REQUEST['legend'])   : "hide";


$ganglia_images = array(
	"Kafka Producer Events"               => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Kafka+Producer+Events&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg[]=kafka_producer_AsyncProducerStats.%2AAsyncProducerEvents&gtype=stack&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Kafka+Producer+Events&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg%5B%5D=kafka_producer_AsyncProducerStats.*AsyncProducerEvents&gtype=stack&glegend=show&aggregate=1",
	),
	"Kafka Producer Dropped Events"       => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Kafka+Producer+Drops&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg[]=kafka_producer_AsyncProducerStats.%2AAsyncProducerDroppedEvents&gtype=stack&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Kafka+Producer+Drops&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg%5B%5D=kafka_producer_AsyncProducerStats.*AsyncProducerDroppedEvents&gtype=stack&glegend=show&aggregate=1",
	),
	"Kafka Produce Requests Per Second"   => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Kafka+Producer+Requests+Per+Second&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg[]=kafka_producer_KafkaProducerStats.%2AProduceRequestsPerSecond&gtype=stack&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Kafka+Producer+Requests+Per+Second&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg%5B%5D=kafka_producer_KafkaProducerStats.*ProduceRequestsPerSecond&gtype=stack&glegend=show&aggregate=1",
	),
	"Kafka Producer Num Produce Requests" => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Kafka+Producer+Num+Produce+Requests+&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg[]=kafka_producer_KafkaProducerStats.%2ANumProduceRequests&gtype=stack&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Kafka+Producer+Num+Produce+Requests+&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd&mreg%5B%5D=kafka_producer_KafkaProducerStats.*NumProduceRequests&gtype=stack&glegend=show&aggregate=1",
	),
	"Kafka Broker Bytes In"               => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Kafka+Broker+BytesIn&vl=&x=&n=0&hreg[]=analytics102%281%7C2%29&mreg[]=kafka_server_BrokerTopicStat.BytesIn&gtype=stack&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Kafka+Broker+BytesIn&vl=&x=&n=0&hreg%5B%5D=analytics102(1%7C2)&mreg%5B%5D=kafka_server_BrokerTopicStat.BytesIn&gtype=stack&glegend=show&aggregate=1",
	),
	"Kafka Broker Messages In"            => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Kafka+MessagesIn&vl=&x=&n=0&hreg[]=analytics102%5B12%5D&mreg[]=kafka_server_BrokerTopicStat.MessagesIn&gtype=stack&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Kafka+MessagesIn&vl=&x=&n=0&hreg%5B%5D=analytics102%5B12%5D&mreg%5B%5D=kafka_server_BrokerTopicStat.MessagesIn&gtype=stack&glegend=show&aggregate=1",
	),
	"udp2log Webrequest Packet Loss"      => array(
		'src'  => "http://ganglia.wikimedia.org/latest/graph.php?r=$period&z=xlarge&title=Analytics+Webrequest+Packet+Loss&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd.eqiad.wmnet&mreg[]=packet_loss_average&gtype=line&glegend=$legend&aggregate=1",
		'href' => "http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=Analytics+Webrequest+Packet+Loss&vl=&x=&n=&hreg%5B%5D=analytics10%5Cd%5Cd.eqiad.wmnet&mreg%5B%5D=packet_loss_average&gtype=line&glegend=show&aggregate=1",
	),
);


?>
<html>
<head>
<!-- Bootstrap -->
    <link href="/bootstrap/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

<div class="container">

<table border="0" cellspacing="5" cellpadding="5">
<?
$i = 0;
foreach($ganglia_images as $name => $image) {
?>
<? if ($i % $columns == 0) { ?>
	<tr>
<? } ?>
		<td>
			<h4><?= $name ?></h2>
			<a href="<?= $image['href'] ?>"><img width="<?= $image_width ?>" src="<?= $image['src'] ?>" /></a>
		</td>
<? if ($i+1 % $columns == 0) { ?>
	</tr>
<? } ?>

<? $i++; ?>
<? } ?>
</table>

<div>
</body>