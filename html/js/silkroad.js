SetupSilkRoadItems = function(data) {
    $(".silkroads-list").html("");

    if (data) {
        $.each(data, function(i, silkroad) {
            var element = '<div class="silkroad-list" id="silkroaditem-' + i + '"><img src="https://cfx-nui-qb-inventory/html/images/'+i+'.webp" class="silkroad-list-img"><div class="silkroad-list-top">' + 'Item: ' + silkroad.label + '</div> <div class="silkroad-list-bottom">' + 'Cost: ' + silkroad.cost + ' qbit(s)</div><div class="silkroad-list-buttons">  <i class="fas fa-shopping-cart accept-silkroad"></i></div></div>'

            $(".silkroads-list").append(element);
            $("#silkroaditem-" + i).data('id', i);
            $("#silkroaditem-" + i).data('label', silkroad.label);
        });
    } else {
        var element = '<div class="silkroad-list"><div class="no-silkroads">There are no boosts available.</div></div>'
        $(".silkroads-list").append(element);
    }
}

$(document).on('click', '.accept-silkroad', function(event) {
    event.preventDefault();

    var SilkRoadId = $(this).parent().parent().attr('id');
    var SilkRoadItem = $("#" + SilkRoadId).data('id');
    var SilkRoadItemLabel = $("#" + SilkRoadId).data('label');

    $.post('https://qb-phone/SilkRoadBuyItem', JSON.stringify({
        item: SilkRoadItem,
        label: SilkRoadItemLabel,
    }))
});