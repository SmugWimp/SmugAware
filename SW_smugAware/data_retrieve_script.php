<?php
	// Q1
	define("MY_URL", "http://www.yourserver.com/data/aircraft.json");
	// define("MY_URL", "http://xxx.xxx.xxx.xxx/data/aircraft.json"); // an ip works too.
	// my raspberry pi resides on my home network. This URL should point to your raspberry pi.
	// I have my router with port forwarding to provide external access. But I use this script on
	// my hosted server so millions don't query the home network.
	//
	//// Leave this alone... it loops once per second for 15 minutes, then stops.
	//// We setup a cron job to run once per minute, triggering this script.
	//// */15	*	*	*	*	/opt/php54/bin/php /path/to/script/thisscriptname.php >/dev/null 2>&1
	//// if you need to stop the script, create a file in the directory called 'key.txt'. It can be blank.
	//// delete it when you're ready to let the script roll again...
	//
	// used to be time limit of 60, and a count of 59. Mod' to see if I can get it to last 15 min...
	//	
	//
			/* with dump1090 v3.3 came new data and filenames. this corrects the issues.
			$success = file_get_contents(MY_URL);			
			$myJson = json_decode($success);
			$myAircraft = $myJson->aircraft;
			$newJson = json_encode($myAircraft);
			$myResult = file_put_contents("/home/smugwimp/public_html/mgps/apps/flightaware/data.json", $newJson);
			*/

	$start = microtime(true);
	set_time_limit(900); // 900 seconds divided by 60 seconds = 15 minutes.
	// my hosting provider won't allow cron jobs any more frequent, so you have 15 minute scripts.
	// if you need it longer or shorter that's where you make your change, in seconds. No decimals.
	// ensure your loop count is also adjusted accordingly
	for ($i = 0; $i < 899; ++$i) {
		if ($myBool == False) {
			$myBool = file_exists("/path/to/your/data/key.txt");
			//  while you're playing with the script, create a blank file called 'key.txt' to render the script moot.
			$success = file_get_contents(MY_URL); // get it from the URL to your dump1090 box			
			$oldJson = json_decode($success); // decode the result
			$myAircraft = $oldJson->aircraft; // strip off the aircraft value, if any
			$newJson = json_encode($myAircraft); // re-encode the json value
			$myResult = file_put_contents("/path/to/your/data/data.json", $newJson);
			// write it to your file, to be read by everyone's copy of the mobile app.
			// the file was originally called 'data.json' so that name shall stay.
			// you can change it if you wish; that's just the way I started out.
 
		} else {
//			$success = file_get_contents("/home/smugwimp/public_html/mgps/apps/flightaware/test_data.json");
//			$myResult = file_put_contents("/home/smugwimp/public_html/mgps/apps/flightaware/data.json", $success);
		}
		time_sleep_until($start + $i + 1);
//		unlink("/home/smugwimp/public_html/mgps/apps/flightaware/key.txt");
	}


?>

