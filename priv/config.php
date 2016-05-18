<?php
	$conn=mysqli_connect("localhost","root","","");
			// Check connection
	if (mysqli_connect_errno()) {
		echo "Failed to connect to MySQL: " . mysqli_connect_error();
	}
	$request_body = file_get_contents('php://input');
	$phpArray= (array)json_decode($request_body, true);
	$fname = $phpArray['FirstName'];
	$lname = $phpArray['LastName'];
	$email = $phpArray['Email'];
			
			
	$sql = "INSERT INTO cmpe280.downloadusers values ('$fname','$lname','$email')";
			
	if (!mysqli_query($conn,$sql)) {
		die('User is not added - Error: ' . mysqli_error($conn));
	}
	echo "User Added Successfully";			
				
	mysqli_close($conn);
	
	$filePath = $_SERVER['DOCUMENT_ROOT']."/Team Website/files/Automating-Stimulus-Fund-Reporting.pdf";
    if(file_exists($filePath)) {
        $fileName = basename($filePath);
        $fileSize = filesize($filePath);

        // Output headers.
        header("Cache-Control: private");
        header("Content-Type: application/stream");
        header("Content-Length: ".$fileSize);
        header("Content-Disposition: attachment; filename=".$fileName);

        // Output file.
        readfile ($filePath);                   
    }
    else {
        die('The provided file path is not valid.');
    }
?>