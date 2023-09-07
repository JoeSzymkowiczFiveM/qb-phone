$(document).on('click', '.garage-vehicle', function(e){
    e.preventDefault();

    $(".garage-homescreen").animate({
        left: 30+"vh"
    }, 200);
    $(".garage-detailscreen").animate({
        left: 0+"vh"
    }, 200);

    var Id = $(this).attr('id');
    var VehData = $("#"+Id).data('VehicleData');
    SetupDetails(VehData);  
});

$(document).on('click', '.garage-cardetails-footer', function(e){
    e.preventDefault();

    $(".garage-homescreen").animate({
        left: 00+"vh"
    }, 200);
    $(".garage-detailscreen").animate({
        left: -30+"vh"
    }, 200);
});

SetupGarageVehicles = function(Vehicles) {
    $(".garage-vehicles").html("");
    if (Vehicles != null) {
        $.each(Vehicles, function(i, vehicle){
            var Element = '<div class="garage-vehicle" id="vehicle-'+i+'"> <span class="garage-vehicle-firstletter">'+vehicle.brand.charAt(0)+'</span> <span class="garage-vehicle-name">'+vehicle.fullname+'</span> </div>';
            
            $(".garage-vehicles").append(Element);
            $("#vehicle-"+i).data('VehicleData', vehicle);
        });
    }
}

SetupDetails = function(data) {
    $(".vehicle-brand").find(".vehicle-answer").html(data.brand);
    $(".vehicle-model").find(".vehicle-answer").html(data.model);
    $(".vehicle-plate").find(".vehicle-answer").html(data.plate);
    $(".vehicle-garage").find(".vehicle-answer").html(data.garage);
    $(".vehicle-status").find(".vehicle-answer").html(data.state);
    $(".vehicle-fuel").find(".vehicle-answer").html(Math.ceil(data.fuel)+"%");
    $(".vehicle-engine").find(".vehicle-answer").html(Math.ceil(data.engine / 10)+"%");
    $(".vehicle-body").find(".vehicle-answer").html(Math.ceil(data.body / 10)+"%");
}

$(document).on('click', '.vehicle-plate', function(e){
    e.preventDefault();
    var textArea = document.createElement('textarea');
    const text = $(".vehicle-plate").find(".vehicle-answer").text()

    textArea.value = text;

    // Avoid scrolling to bottom
    textArea.style.top = '0';
    textArea.style.left = '0';
    textArea.style.position = 'fixed';

    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        document.execCommand('copy');
    } catch (err) {}

    document.body.removeChild(textArea);

    QB.Phone.Notifications.Add("fas fa-warehouse", "Vehicles", "License Plate copied!", "#ee5253", 1500);
});