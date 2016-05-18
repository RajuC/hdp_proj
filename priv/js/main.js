jQuery(function($) {'use strict',

	//#main-slider
	$(function(){
		$('#main-slider.carousel').carousel({
			interval: 8,
			pause: true
		});
	});
	
	
	
  $(document).ready(function(){
    $('li img').on('click',function(){
      var src = $(this).attr('src');
      var name = $(this).attr('id');
      var position = $(this).attr('name');
      var desc = $(this).attr('data-desc');
      var img = '<div style="float: inherit; font-size: 30px">' + position + '</div><div style="float: inherit; font-size: 20px; margin-top: 10px;">' + desc + '</div><img src="' + src + '" class="img-responsive"/> ';
      var text1 = '<span style="font-size: 30px; color: orange;">' + name + '</span>';
      $('#myModal').modal();
      $('#myModal').on('shown.bs.modal', function(){
        $('#myModal .modal-header').html(text1);
        $('#myModal .modal-body').html(img);
      });
      $('#myModal').on('hidden.bs.modal', function(){
        $('#myModal .modal-header').html('');
        $('#myModal .modal-body').html('');
      });
    });
  });
 

		 
  $(document).ready(function(){
    $('p a').on('click',function(){
     var src = $(this).attr('src');
      var name = $(this).attr('id');
      
      var mobile = '<div style="float: inherit; font-size: 30px">'+'<embed src="'+src+'" width="100%" height="400" alt="pdf" pluginspage="http://www.adobe.com/products/acrobat/readstep2.html">' ;
		var text1 = '<span style="font-size: 30px; color: orange;">' +name+ '</span>';
		 
      $('#myModal').modal();
      $('#myModal').on('shown.bs.modal', function(){
        $('#myModal .modal-header').html(text1);
        $('#myModal .modal-body').html(mobile);
      });
      $('#myModal').on('hidden.bs.modal', function(){
        $('#myModal .modal-header').html('');
        $('#myModal .modal-body').html('');
      });
    });
  });
 
 
 $(document).ready(function(){ 
    $('#mytooltip').tooltip();
	 $('#mytooltip1').tooltip();
	  $('#mytooltip2').tooltip();
	   $('#mytooltip3').tooltip();
	   
  });

});