$(document).on('click', '#btnDownload', function(){
	$("#results").text("");
	var ObjToJSON = new Object();
		ObjToJSON.FirstName=document.getElementById("firstName").value;
		ObjToJSON.LastName=document.getElementById("lastName").value;
		ObjToJSON.Email=document.getElementById("email").value;
	$.ajax({
		url: $("#myForm").attr("action"),
		type: "POST",
		data: JSON.stringify(ObjToJSON),
		processData: false,
		contentType: "application/json; charset=UTF-8",
		complete: function()
			{
				$("#results").text("Addition Successful!!!");
			}
	});
});

$(document).on('click', '#btnCancel', function(){
	$(location).attr('href','home.html');
});

$("#myForm").submit(function(){return false;});