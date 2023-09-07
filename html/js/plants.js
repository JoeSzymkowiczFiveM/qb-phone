SetupPlants = function(data) {
    $(".plants-list").html("");

    if (data.length > 0) {
        $.each(data, function(i, plant) {
            //console.log(plant)
            if (plant.type == 'weed') {
                plant.sort = plant.sort + ' ' + plant.type
            }
            var element = '<div class="plant-list" id="plantid-' + i + '"> <div class="plant-list-health">' + plant.health + '</div> <div class="plant-list-top">' + 'Nutrition: ' + plant.food + '</div> <div class="plant-list-middle">' + 'Type: ' + QB.Phone.Functions.CamelCase(plant.sort) + '</div> <div class="plant-list-bottom">' + 'Location: ' + plant.zone + '</div></div>'
            $(".plants-list").append(element);
            $("#plantid-" + i).data('coords', plant.coords);
        });
    } else {
        var element = '<div class="plant-list"><div class="no-plants">There are no monitored plants.</div></div>'
        $(".plants-list").append(element);
    }
}

$(document).on('click', '.plant-list', function(e) {
    e.preventDefault();

    var PlantId = $(this).attr('id');
    var PlantData = $("#" + PlantId).data('coords');

    $.post('https://qb-phone/SetGPSLocation', JSON.stringify({
        coords: PlantData
    }))
});