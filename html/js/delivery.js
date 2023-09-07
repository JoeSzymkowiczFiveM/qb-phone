var working = false
SetupDeliveries = function(data) {
    $(".deliveries-list").html("");

    if (data.jobs && Object.keys(data.jobs).length > 0) {
        $.each(data.jobs, function(i, delivery) {
            const expireDate = delivery.expire * 1000;
            const dateNow = Date.now();
            const diff = Math.round((expireDate - dateNow) / 60000);
            var element = '<div class="delivery-list" id="deliveryid-' + i + '"> <div class="delivery-list-health">' + diff + '</div> <div class="delivery-list-top">' + 'Location: ' + delivery.area + '</div> <div class="delivery-list-bottom">' + 'Items: ' + delivery.itemCount + ' ' + delivery.itemProper + '(s)</div></div>'
            $(".deliveries-list").append(element);
            $("#deliveryid-" + i).data('coords', delivery.coords);
        });
    } else {
        var element = '<div class="plant-list"><div class="no-deliveries">There are no deliveries.</div></div>'
        $(".deliveries-list").append(element);
    }
}

$(document).on('click', '.delivery-list', function(e) {
    e.preventDefault();

    var DeliveryId = $(this).attr('id');
    var DeliveryData = $("#" + DeliveryId).data('coords');

    $.post('https://qb-phone/SetGPSLocation', JSON.stringify({
        coords: DeliveryData
    }))
});

$(document).on('click', '.deliveries-general-action', function(e) {
    e.preventDefault();
    $.post('https://qb-phone/ToggleDeliveries', JSON.stringify({}))
    if (working === true) {
        working = !working
        $(".deliveries-list").html("");
        $(".deliveries-general-action-title").text('Start Deliveries')
        var element = '<div class="plant-list"><div class="no-deliveries">There are no deliveries.</div></div>'
        $(".deliveries-list").append(element);
    } else if (working === false) {
        working = !working
        $(".deliveries-general-action-title").text('End Deliveries')
    }
});