$(document).on('click', '.pingstab-general-action', function(e) {
    e.preventDefault();
    var player = $(".pings-input-number").val();
    $.post('https://qb-phone/DoPing', JSON.stringify({
        PlayerNumber: player,
    }))
    QB.Phone.Functions.Close();
});