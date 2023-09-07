var OpenedId = null;

$(document).on('click', '.auctions-add', function(e) {
    e.preventDefault();

    $(".auctions-home").animate({
        left: 30 + "vh"
    });
    $(".new-auction").animate({
        left: 0 + "vh"
    });
    $(".new-auction-name").val('');
    $(".new-auction-textarea").val('');
    $("#new-auction-header-text").text('Add Note')

    $(".new-auction-footer-item").css({
        width: "50%",
    });
    $("#new-auction-delete").css({ "display": "none" });
});

$(document).on('click', '#new-auction-back', function(e) {
    e.preventDefault();

    $(".auctions-home").animate({
        left: 0 + "vh"
    });
    $(".new-auction").animate({
        left: -30 + "vh"
    });
});

$(document).on('click', '#new-auction-delete', function(e) {
    e.preventDefault();

    $.post('https://qb-phone/DeleteNote', JSON.stringify({
        id: OpenedId,
    }));

    $(".auctions-home").animate({
        left: 0 + "vh"
    });
    $(".new-auction").animate({
        left: -30 + "vh"
    });
});

$(document).on('click', '#new-auction-submit', function(e) {
    e.preventDefault();
    
    var auction = $(".new-auction-textarea").val();
    var name = $(".new-auction-name").val();

    if (auction !== "") {
        $(".auctions-home").animate({
            left: 0 + "vh"
        });
        $(".new-auction").animate({
            left: -30 + "vh"
        });
        if ( $("#new-auction-header-text").text() === 'Add Note' ) {
            $.post('https://qb-phone/PostNote', JSON.stringify({
                body: auction,
                title: name,
                //date: date
            }));
        } else if ( $("#new-auction-header-text").text() === 'Edit Note') {
            $.post('https://qb-phone/EditNote', JSON.stringify({
                body: auction,
                title: name,
                id: OpenedId,
            }));
        }
        
    } else {
        QB.Phone.Notifications.Add("fas fa-comment", "Notes", "You can't post an empty auction!", "#ff8f1a", 2000);
    }
});

$(document).on('click', '.auction', function(e) {
    
    $(".auctions-home").animate({
        left: 30 + "vh"
    });
    $(".new-auction").animate({
        left: 0 + "vh"
    });

    var Id = $(this).attr('id');
    var NoteData = $("#"+Id).data('NoteData');
    if ( Id ) { 
        OpenedId = Id.substring(5)
        
        $(".new-auction-name").val(NoteData.title);
        $(".new-auction-textarea").val(NoteData.body);
        $("#new-auction-header-text").text('Edit Note')

        $(".new-auction-footer-item").css({
            width: "33%",
        });
        $("#new-auction-delete").css({ "display": "block" });
    } else {
        $(".new-auction-name").val('');
        $(".new-auction-textarea").val('');
        $("#new-auction-header-text").text('Add Note')

        $(".new-auction-footer-item").css({
            width: "50%",
        });
        $("#new-auction-delete").css({ "display": "none" });
    }
});

RefreshAuctions = function(Auctions) {
    $(".auctions-list").html("");
    if (Object.keys(Auctions).length > 0) {
        $.each(Auctions, function(i, auction) {
            var element = '<div class="auction" id="auction-'+auction.id+'"><span class="auction-sender">' + truncateAuctions(auction.title) + `</span><p>` + truncateAuctions(auction.body) + '</p></div>';
            $(".auctions-list").prepend(element);
            $("#auction-"+auction.id).data('NoteData', auction);
        });
    } else if (Object.keys(Auctions).length == 0) {
        $(".auctions-list").html("");
        var element = '<div class="auction"><span class="auction-sender">There are no auctions yet!</span></div>';
        $(".auctions-list").append(element);
    } 
}

function truncateAuctions(input) {
    if (input.length > 30) {
        return input.substring(0, 30) + '...';
    }
    return input;
};