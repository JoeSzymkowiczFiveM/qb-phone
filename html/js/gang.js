SetupGang = function(data) {
    $(".gang-list").html("");
    console.log(data)

    if (data && data.length > 0) {
        $.each(data, function(i, gang) {
            var FirstLetter = (gang.charinfo.firstname).charAt(0);
            var FullName = gang.charinfo.firstname + ' ' + gang.charinfo.lastname
            var element = '<div class="gangmembers-list" id="gangid-' + gang.citizenid + '"> <div class="gangmembers-list-class">' + FirstLetter + '</div> <div class="gangmembers-list-top">' + 'Name: ' + FullName + '</div> <div class="gangmembers-list-bottom">' + 'Level: ' + gang.gang.grade.name + '</div><div class="gangmembers-list-buttons"> <i class="fas fa-times-circle decline-gangmembers"></i> </div></div>'

            $(".gang-list").append(element);
            $("#gangid-" + gang.citizenid).data('id', gang.citizenid);
        });
    } else {
        var element = '<div class="gangmembers-list"><div class="no-gangmembers">There are no members.</div></div>'
        $(".gangmembers-list").append(element);
    }
}

$(document).on('click', '.decline-gangmembers', function(event) {
    event.preventDefault();

    var GangmemberId = $(this).parent().parent().attr('id');
    var GangmemberDataId = $("#" + GangmemberId).data('id');

    $("#" + GangmemberId).animate({
        left: 30 + "vh",
    }, 300, function() {
        setTimeout(function() {
            $("#" + GangmemberId).remove();
        }, 100);
    });

    // $.post('https://qb-phone/FireGangmember', JSON.stringify({
    //     id: GangmemberDataId,
    // }))
    console.log(GangmemberDataId)
});
