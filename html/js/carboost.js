SetupCarBoosts = function(data) {
    $(".carboosts-list").html("");

    if (data && data.length > 0) {
        $.each(data, function(i, carboost) {
            //console.log(carboost)
            if (carboost.vinScratch) {
                var element = '<div class="carboost-list" id="carboostid-' + carboost.id + '"> <div class="carboost-list-class">' + carboost.class + '</div> <div class="carboost-list-top">' + 'Model: ' + carboost.model + '</div> <div class="carboost-list-middle">' + 'Scratch: ' + carboost.vinScratchCost + ' qbit(s)</div> <div class="carboost-list-bottom">' + 'Status: ' + carboost.status + '</div><div class="carboost-list-buttons"> <i class="fas fa-exclamation-circle vin-carboost"></i> <i class="fas fa-check-circle accept-carboost"></i> <i class="fas fa-times-circle decline-carboost"></i> </div></div>'
            } else {
                var element = '<div class="carboost-list" id="carboostid-' + carboost.id + '"> <div class="carboost-list-class">' + carboost.class + '</div> <div class="carboost-list-top">' + 'Model: ' + carboost.model + '</div> <div class="carboost-list-bottom">' + 'Status: ' + carboost.status + '</div><div class="carboost-list-buttons"> <i class="fas fa-check-circle accept-carboost"></i> <i class="fas fa-times-circle decline-carboost"></i> </div></div>'
            }
            $(".carboosts-list").append(element);
            $("#carboostid-" + carboost.id).data('id', carboost.id);
            $("#carboostid-" + carboost.id).data('mission', carboost.mission);
            $("#carboostid-" + carboost.id).data('cost', carboost.vinScratchCost);
        });
    } else {
        var element = '<div class="carboost-list"><div class="no-carboosts">There are no boosts available.</div></div>'
        $(".carboosts-list").append(element);
    }
}

$(document).on('click', '.accept-carboost', function(event) {
    event.preventDefault();

    var CarboostId = $(this).parent().parent().attr('id');
    var CarboostData = $("#" + CarboostId).data('id');
    //console.log(CarboostData)

    $.post('https://qb-phone/StartBoost', JSON.stringify({
        id: CarboostData,
        vin: false,
    }))
});

$(document).on('click', '.decline-carboost', function(event) {
    event.preventDefault();

    var CarboostId = $(this).parent().parent().attr('id');
    var CarboostDataId = $("#" + CarboostId).data('id');
    var CarboostDataMission = $("#" + CarboostId).data('mission');

    $("#" + CarboostId).animate({
        left: 30 + "vh",
    }, 300, function() {
        setTimeout(function() {
            $("#" + CarboostId).remove();
        }, 100);
    });

    $.post('https://qb-phone/DeclineCancelBoost', JSON.stringify({
        id: CarboostDataId,
        mission: CarboostDataMission,
    }))
});

$(document).on('click', '.vin-carboost', function(event) {
    event.preventDefault();

    var CarboostId = $(this).parent().parent().attr('id');
    var CarboostData = $("#" + CarboostId).data('id');
    var CarboostCost = $("#" + CarboostId).data('cost');
    //console.log(CarboostData)

    $.post('https://qb-phone/StartBoost', JSON.stringify({
        id: CarboostData,
        cost: CarboostCost,
        vin: true,
    }))
});