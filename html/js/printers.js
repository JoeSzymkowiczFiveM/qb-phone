var PrinterId

/*Dropdown Menu*/
$('.printerdropdown').click(function() {
    $(this).attr('tabindex', 1).focus();
    $(this).toggleClass('active');
    $(this).find('.printerdropdown-menu').slideToggle(300);
});

$('.printerdropdown').focusout(function() {
    $(this).removeClass('active');
    $(this).find('.printerdropdown-menu').slideUp(300);
});

$(document).on('click', '.printerdropdown .printerdropdown-menu li', function(e) {
    $(this).parents('.printerdropdown').find('span').text($(this).text());
    $(this).parents('.printerdropdown').find('input').attr('value', $(this).attr('id'));
    
    PrinterId = $(this).attr('id');
});

/*End Dropdown Menu*/

function SetupPrinters(Printers) {
    if (Printers !== undefined && Printers !== null) {
        $(".printerdropdown-menu").html("");
        $.each(Printers, function(i, printer) {
            var elem = '<li id="' + printer.name + '">' + printer.label + '</li>';
            $(".printerdropdown-menu").append(elem);
        });
    }
}

$(document).on('click', '#setup-printer-accept', function(e) {
    e.preventDefault();

    var url = $(".printers-setup-url").val();
    var copies = $(".printers-setup-copies").val();
    if (url != '' && PrinterId ) {
        $.post('https://qb-phone/PrintDocument', JSON.stringify({
            printer: PrinterId,
            url: url,
            copies: copies,
        }), function(Response) {
            //console.log(Response)
            if (Response === true) {
                $(".printers-setup-url").val("");
                $(".printers-setup-copies").val(1);
            }
        });
    }
});

$(document).on('click', '#setup-printer-cancel', function(e) {
    e.preventDefault();

    $(".printers-setup-url").val("");
    $(".printers-setup-copies").val(1);
});