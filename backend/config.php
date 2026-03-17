<?php
// config.php
// FIX: removed header("Content-Type: …") — every endpoint that includes this
// file already sets the correct headers before the include, so the second call
// was redundant. In some server configurations a duplicate Content-Type header
// can cause response-parsing errors on the client.
include 'connection.php';
?>
