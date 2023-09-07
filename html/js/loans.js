SetupLoans = function(data) {
    $(".loans-list").html("");

    if (data.length > 0) {
        $.each(data, function(i, loan) {
            var date = new Date(loan.start_date)
            var status = getLoanStatus(loan)
            var element = '<div class="loan-list" id="loanid-' + i + '"> <div class="loan-list-top">' + 'Loan Id: ' + loan.id + ' - ' + status + '</div> <div class="loan-list-middle">' + 'Remaining Amount: ' + formatter.format(loan.remaining_amount) + '</div> <div class="loan-list-bottom">' + 'Start Date: ' + date.toDateString() + '</div></div>'
            $(".loans-list").append(element);
            //$("#plantid-" + i).data('coords', plant.coords);
        });
    } else {
        var element = '<div class="loan-list"><div class="no-loans">There are no active loans.</div></div>'
        $(".loans-list").append(element);
    }
}

/* $(document).on('click', '.plant-list', function(e) {
    e.preventDefault();

    var PlantId = $(this).attr('id');
    var PlantData = $("#" + PlantId).data('coords');

    $.post('https://qb-phone/SetGPSLocation', JSON.stringify({
        coords: PlantData
    }))
}); */

var formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  
    // These options are needed to round to whole numbers if that's what you want.
    //minimumFractionDigits: 0, // (this suffices for whole numbers, but will print 2500.10 as $2,500.1)
    //maximumFractionDigits: 0, // (causes 2500.99 to be printed as $2,501)
});

function WithoutTime(dateTime) {
    var date = new Date(dateTime.getTime());
    date.setHours(0, 0, 0, 0);
    return date;
}

function getLoanStatus(data) {
    var status = ''
    if (!data.paid && !data.overdue) {
        status = 'UNPAID'
    } else if (!data.paid && data.overdue){
        status = 'OVERDUE'
    } else if (data.paid && !data.overdue) {
        status = 'ACTIVE'
    }
    return status
}