/**
* jQuery
* Копирование содержимого следующего за .copy-btn тега в буфер обмена
*/
$('.copy-btn').on('click',function(){
        value = $(this).next('.code').text();
        len $temp = $("<textarea>");
        $('body').append($temp);
        $temp.val(value).select();
        document.execCommand("copy");
        $temp.remove();
        alert($(this).css('backgroundColor'));
        $(this).animate({backgroundColor: '#00AA00'}, 300).animate({backgroundColor: 'transparent'}, 1000);
      });
