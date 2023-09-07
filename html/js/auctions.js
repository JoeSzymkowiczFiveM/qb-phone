var OpenedId = null;

SetupAuctionItems = function(data) {
    $(".auctions-list").html("");

    if (data.length > 0) {
        $.each(data, function(i, auction) {
            var element = '<div class="auction-list" id="auctionitem-' + auction._id + '"><img src="https://cfx-nui-qb-inventory/html/images/'+auction.item+'.webp" class="auction-list-img"><div class="auction-list-top">' + auction.label + '</div> <div class="auction-list-middle">' + 'Current Bid: $' + auction.currentBidPrice + '</div><div class="auction-list-bottom">' + 'Buy It Now: $' + auction.buyItNowPrice + '</div></div>'

            $(".auctions-list").append(element);
            $("#auctionitem-"+auction._id).data('AuctionData', auction);
        });
    } else {
        var element = '<div class="auction-list"><div class="no-auctions">There are no auctions available.</div></div>'
        $(".auctions-list").append(element);
    }
}

CloseAuctionPage = function() {
    $(".auctions-list").animate({
        left: 0 + "vh"
    });
    $(".open-auction").animate({
        left: -30 + "vh"
    });
}

$(document).on('click', '.auction-list', function(e) {
    var Id = $(this).attr('id');
    var AuctionData = $("#"+Id).data('AuctionData');

    if ( Id ) {
        $(".auction-open-img").html("");
    
        $(".auctions-list").animate({
            left: 30 + "vh"
        });
        $(".open-auction").animate({
            left: 0 + "vh"
        });

        var Quality = ItemQualityAdjustment(AuctionData.itemcreated, AuctionData.degrade)
        OpenedId = AuctionData._id
        $("#open-auction-header-text").text(AuctionData.label);

        $("#open-auction-body-bidPrice-value").text(AuctionData.currentBidPrice);
        $("#open-auction-body-increment-value").text(AuctionData.increment);
        $("#open-auction-body-buyPrice-value").text(AuctionData.buyItNowPrice);
        $("#open-auction-body-quality-value").text(Quality);
        $("#open-auction-body-high-bidder").text('You have the highest bid already');
        $(".open-auction-body-quality-img").attr("src",'https://cfx-nui-qb-inventory/html/images/'+AuctionData.item+'.webp');

        // if (Quality !== '0 %') {
        //     $("#open-auction-body-quality-value").css({ "color": '#202020' });
        // } else {
        //     $("#open-auction-body-quality-value").css({ "color": '#c53838' });
        // }

        if (QB.Phone.Data.PlayerData.citizenid === AuctionData.highBidder) {
            $("#open-auction-buy").css({ width: "50%" });
            $("#open-auction-back").css({ width: "50%" });
            $("#open-auction-bid").css({ "display": "none" });
            $("#open-auction-body-high-bidder").css({ "display": "block" });
        } else {
            $("#open-auction-buy").css({ width: "33.3%" });
            $("#open-auction-back").css({ width: "33.3%" });
            $("#open-auction-bid").css({ width: "33.3%" });
            $("#open-auction-bid").css({ "display": "block" });
            $("#open-auction-body-high-bidder").css({ "display": "none" });
        }
    }
});

$(document).on('click', '#open-auction-back', function(e) {
    e.preventDefault();

    $(".auctions-list").animate({
        left: 0 + "vh"
    });
    $(".open-auction").animate({
        left: -30 + "vh"
    });
});

$(document).on('click', '#open-auction-buy', function(e) {
    event.preventDefault();

    $.post('https://qb-phone/AuctionBuyItem', JSON.stringify({
        id: OpenedId,
    }))
});

$(document).on('click', '#open-auction-bid', function(e) {
    event.preventDefault();

    $.post('https://qb-phone/AuctionBidItem', JSON.stringify({
        id: OpenedId,
    }))
});

function ItemQualityAdjustment(time, degrade) {
    if (degrade === 0) {
        return 100
    }
    time = time ? Math.min(...time) : Date.now()
    const TimeAllowed = 60 * 60 * 24 * 28; // 28 is max days of decay to 0
    const DecayRate = degrade ? degrade : 1;
    const TimeExtra = TimeAllowed * DecayRate;
    const StartDate = time * 1000;
    const dateNow = Date.now();
    
    var quality = 100 + (100 - ((dateNow - StartDate) / TimeExtra) * 100) / 1000;
    if (quality > 100) { quality = 100 } else if (quality < 0) { quality = 0 }
    return Math.ceil(quality)+' %'
}