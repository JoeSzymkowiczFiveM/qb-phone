var OpenedRaceElement = null;

$(document).ready(function() {
    $('[data-toggle="auctiontooltip"]').tooltip();
});

$(document).on('click', '.auctions-auction', function(e) {
    e.preventDefault();

    var OpenSize = "15vh";
    var DefaultSize = "9vh";
    var AuctionData = $(this).data('AuctionData');
    var IsRacer = IsInRace(QB.Phone.Data.PlayerData.citizenid, AuctionData.AuctionData.Racers)

    if (!RaceData.RaceData.Started || IsRacer) {
        if (OpenedRaceElement === null) {
            $(this).css({ "height": OpenSize });
            setTimeout(() => {
                $(this).find('.auction-buttons').fadeIn(100);
            }, 100);
            OpenedRaceElement = this;
        } else if (OpenedRaceElement == this) {
            $(this).find('.auction-buttons').fadeOut(20);
            $(this).css({ "height": DefaultSize });
            OpenedRaceElement = null;
        } else {
            $(OpenedRaceElement).find('.auction-buttons').hide();
            $(OpenedRaceElement).css({ "height": DefaultSize });
            $(this).css({ "height": OpenSize });
            setTimeout(() => {
                $(this).find('.auction-buttons').fadeIn(100);
            }, 100);
            OpenedRaceElement = this;
        }
    } else {
        QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "The auction has already started..", "#1DA1F2");
    }
});

function GetAmountOfRacers(Racers) {
    var retval = 0
    $.each(Racers, function(i, racer) {
        retval = retval + 1
    });
    return retval
}

function IsInRace(CitizenId, Racers) {
    var retval = false;
    $.each(Racers, function(cid, racer) {
        if (cid == CitizenId) {
            retval = true;
        }
    });
    return retval
}

function IsCreator(CitizenId, RaceData) {
    var retval = false;
    if (RaceData.SetupCitizenId == CitizenId) {
        retval = true;
    }
    return retval;
}

function SetupAuctions(Auctions) {
    $(".auctions-auctions").html("");
    if (Races.length > 0) {
        Auctions = (Auctions).reverse();
        $.each(Auctions, function(i, auction) {
            var Locked = '<i class="fas fa-unlock"></i> Not started yet';
            if (auction.RaceData.Started) {
                Locked = '<i class="fas fa-lock"></i> Started';
            }
            var LapLabel = "";
            if (auction.Laps == 0) {
                LapLabel = "SPRINT"
            } else {
                if (auction.Laps == 1) {
                    LapLabel = auction.Laps + " Lap";
                } else {
                    LapLabel = auction.Laps + " Laps";
                }
            }
            var InRace = IsInRace(QB.Phone.Data.PlayerData.citizenid, auction.RaceData.Racers);
            var Creator = IsCreator(QB.Phone.Data.PlayerData.citizenid, auction);
            var Buttons = '<div class="auction-buttons"> <div class="auction-button" id="join-auction" data-toggle="racetooltip" data-placement="left" title="Join"><i class="fas fa-sign-in-alt"></i></div>';
            if (InRace) {
                if (!Creator) {
                    Buttons = '<div class="auction-buttons"> <div class="auction-button" id="quit-auction" data-toggle="racetooltip" data-placement="right" title="Quit"><i class="fas fa-sign-out-alt"></i></div>';
                } else {
                    if (!auction.RaceData.Started) {
                        Buttons = '<div class="auction-buttons"> <div class="auction-button" id="start-auction" data-toggle="racetooltip" data-placement="left" title="Start"><i class="fas fa-flag-checkered"></i></div><div class="auction-button" id="quit-auction" data-toggle="racetooltip" data-placement="right" title="Quit"><i class="fas fa-sign-out-alt"></i></div>';
                    } else {
                        Buttons = '<div class="auction-buttons"> <div class="auction-button" id="quit-auction" data-toggle="racetooltip" data-placement="right" title="Quit"><i class="fas fa-sign-out-alt"></i></div>';
                    }
                }
            }
            var Racers = GetAmountOfRacers(auction.RaceData.Racers);
            var element = '<div class="auctions-auction" id="raceid-' + i + '"> <span class="auction-name"><i class="fas fa-flag-checkered"></i> ' + auction.RaceData.RaceName + '</span> <span class="auction-track">' + Locked + '</span> <div class="auction-infomation"> <div class="auction-infomation-tab" id="auction-information-laps">' + LapLabel + '</div> <div class="auction-infomation-tab" id="auction-information-distance">' + auction.RaceData.Distance + ' m</div> <div class="auction-infomation-tab" id="auction-information-player"><i class="fas fa-user"></i> ' + Racers + '</div> </div> ' + Buttons + ' </div> </div>';
            $(".auctions-races").append(element);
            $("#raceid-" + i).data('RaceData', auction);
            if (!auction.RaceData.Started) {
                $("#raceid-" + i).css({ "border-bottom-color": "#34b121" });
            } else {
                $("#raceid-" + i).css({ "border-bottom-color": "#b12121" });
            }
            $('[data-toggle="racetooltip"]').tooltip();
        });
    }
}

$(document).ready(function() {
    $('[data-toggle="auction-setup"]').tooltip();
});

$(document).on('click', '#join-auction', function(e) {
    e.preventDefault();

    var RaceId = $(this).parent().parent().attr('id');
    var Data = $("#" + RaceId).data('RaceData');

    $.post('https://qb-phone/IsInRace', JSON.stringify({}), function(IsInRace) {
        if (!IsInRace) {
            $.post('https://qb-phone/RaceDistanceCheck', JSON.stringify({
                RaceId: Data.RaceId,
                Joined: true,
            }), function(InDistance) {
                if (InDistance) {
                    $.post('https://qb-phone/IsBusyCheck', JSON.stringify({
                        check: "editor"
                    }), function(IsBusy) {
                        if (!IsBusy) {
                            $.post('https://qb-phone/JoinRace', JSON.stringify({
                                RaceData: Data,
                            }));
                            $.post('https://qb-phone/GetAvailableRaces', JSON.stringify({}), function(Races) {
                                SetupRaces(Races);
                            });
                        } else {
                            QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "Je zit in een editor..", "#1DA1F2");
                        }
                    });
                }
            })
        } else {
            QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "Je zit al in een auction..", "#1DA1F2");
        }
    });
});

$(document).on('click', '#quit-auction', function(e) {
    e.preventDefault();

    var RaceId = $(this).parent().parent().attr('id');
    var Data = $("#" + RaceId).data('RaceData');

    $.post('https://qb-phone/LeaveRace', JSON.stringify({
        RaceData: Data,
    }));

    $.post('https://qb-phone/GetAvailableRaces', JSON.stringify({}), function(Races) {
        SetupRaces(Races);
    });
});

$(document).on('click', '#start-auction', function(e) {
    e.preventDefault();


    var RaceId = $(this).parent().parent().attr('id');
    var Data = $("#" + RaceId).data('RaceData');

    $.post('https://qb-phone/StartRace', JSON.stringify({
        RaceData: Data,
    }));

    $.post('https://qb-phone/GetAvailableRaces', JSON.stringify({}), function(Races) {
        SetupRaces(Races);
    });
});

function secondsTimeSpanToHMS(s) {
    var h = Math.floor(s / 3600); //Get whole hours
    s -= h * 3600;
    var m = Math.floor(s / 60); //Get remaining minutes
    s -= m * 60;
    return h + ":" + (m < 10 ? '0' + m : m) + ":" + (s < 10 ? '0' + s : s); //zero padding on minutes and seconds
}


/*Dropdown Menu*/
$('.auctionsDropdown').click(function() {
    $(this).attr('tabindex', 1).focus();
    $(this).toggleClass('active');
    $(this).find('.auctionsDropdown-menu').slideToggle(300);
});

$('.auctionsDropdown').focusout(function() {
    $(this).removeClass('active');
    $(this).find('.auctionsDropdown-menu').slideUp(300);
});

$(document).on('click', '.auctionsDropdown .auctionsDropdown-menu li', function(e) {
    $.post('https://qb-phone/GetTrackData', JSON.stringify({
        RaceId: $(this).attr('id')
    }), function(TrackData) {
        if ((TrackData.CreatorData.charinfo.lastname).length > 8) {
            TrackData.CreatorData.charinfo.lastname = TrackData.CreatorData.charinfo.lastname.substring(0, 8);
        }
        var CreatorTag = TrackData.CreatorData.charinfo.firstname.charAt(0).toUpperCase() + ". " + TrackData.CreatorData.charinfo.lastname;

        $(".racing-setup-information-distance").html('Distance: ' + TrackData.Distance + ' m');
        $(".racing-setup-information-creator").html('Maker: ' + CreatorTag);
        if (TrackData.Records.Holder !== undefined) {
            if (TrackData.Records.Holder[1].length > 8) {
                TrackData.Records.Holder[1] = TrackData.Records.Holder[1].substring(0, 8) + "..";
            }
            var Holder = TrackData.Records.Holder[0].charAt(0).toUpperCase() + ". " + TrackData.Records.Holder[1];
            $(".racing-setup-information-wr").html('WR: ' + secondsTimeSpanToHMS(TrackData.Records.Time) + ' (' + Holder + ')');
        } else {
            $(".racing-setup-information-wr").html('WR: N/A');
        }
    });

    $(this).parents('.auctionsDropdown').find('span').text($(this).text());
    $(this).parents('.auctionsDropdown').find('input').attr('value', $(this).attr('id'));
});
/*End Dropdown Menu*/

$(document).on('click', '#setup-auction', function(e) {
    e.preventDefault();

    $(".auctions-overview").animate({
        left: 30 + "vh"
    }, 300);
    $(".auctions-setup").animate({
        left: 0
    }, 300);

    $.post('https://qb-phone/SetupAuctionItems', JSON.stringify({}), function(AuctionItems) {
        if (AuctionItems !== undefined && AuctionItems !== null) {
            $(".auctionsDropdown-menu").html("");
            $.each(AuctionItems, function(i, item) {
                //if (!item.Started && !item.Waiting) {
                    var elem = '<li id="' + item.i + '">' + 'Slot ' + i + ' - ' + item.label + '</li>';
                    $(".auctionsDropdown-menu").append(elem);
                //}
            });
        }
    });
});

$(document).on('click', '#create-auction', function(e) {
    e.preventDefault();
    $.post('https://qb-phone/IsAuthorizedToCreateRaces', JSON.stringify({}), function(data) {
        if (data.IsAuthorized) {
            if (!data.IsBusy) {
                $.post('https://qb-phone/IsBusyCheck', JSON.stringify({
                    check: "auction"
                }), function(InRace) {
                    if (!InRace) {
                        $(".auctions-create").fadeIn(200);
                    } else {
                        QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You\'re in a auction..", "#1DA1F2");
                    }
                });
            } else {
                QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You are already creating a track..", "#1DA1F2");
            }
        } else {
            QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You do not have permission to create races..", "#1DA1F2");
        }
    });
});

$(document).on('click', '#auctions-create-accept', function(e) {
    e.preventDefault();
    var TrackName = $(".auctions-create-trackname").val();

    if (TrackName !== "" && TrackName !== undefined && TrackName !== null) {
        $.post('https://qb-phone/IsAuthorizedToCreateRaces', JSON.stringify({
            TrackName: TrackName
        }), function(data) {
            if (data.IsAuthorized) {
                if (data.IsNameAvailable) {
                    $.post('https://qb-phone/StartTrackEditor', JSON.stringify({
                        TrackName: TrackName
                    }));
                    $(".auctions-create").fadeOut(200, function() {
                        $(".auctions-create-trackname").val("");
                    });
                } else {
                    QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "This Track Name is not available..", "#1DA1F2");
                }
            } else {
                QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You lack permission to create a Track..", "#1DA1F2");
            }
        });
    } else {
        QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You must enter a Track Name..", "#1DA1F2");
    }
});

$(document).on('click', '#auctions-create-cancel', function(e) {
    e.preventDefault();
    $(".auctions-create").fadeOut(200, function() {
        $(".auctions-create-trackname").val("");
    });
});

$(document).on('click', '#setup-auction-accept', function(e) {
    e.preventDefault();

    var track = $('.dropdown').find('input').attr('value');
    var laps = $(".auctions-setup-laps").val();
    var buyinCost = $(".auctions-setup-buyin").val();

    $.post('https://qb-phone/HasCreatedRace', JSON.stringify({}), function(HasCreatedRace) {
        if (!HasCreatedRace) {
            $.post('https://qb-phone/RaceDistanceCheck', JSON.stringify({
                RaceId: track,
                Joined: false,
            }), function(InDistance) {
                if (InDistance) {
                    if (track !== undefined || track !== null) {
                        if (laps !== "") {
                            $.post('https://qb-phone/CanRaceSetup', JSON.stringify({}), function(CanSetup) {
                                if (CanSetup) {
                                    $.post('https://qb-phone/SetupRace', JSON.stringify({
                                        RaceId: track,
                                        AmountOfLaps: laps,
                                    }))
                                    $(".auctions-overview").animate({
                                        left: 0 + "vh"
                                    }, 300)
                                    $(".auctions-setup").animate({
                                        left: -30 + "vh"
                                    }, 300, function() {
                                        $(".auctions-setup-information-distance").html('Select a Track');
                                        $(".auctions-setup-information-creator").html('Select a Track');
                                        $(".auctions-setup-information-wr").html('Select a Track');
                                        $(".auctions-setup-laps").val("");
                                        $('.dropdown').find('input').removeAttr('value');
                                        $('.dropdown').find('span').text('Select a Track');
                                    });
                                } else {
                                    QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "No races can be created at this time..", "#1DA1F2");
                                }
                            });
                        } else {
                            QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "Fill in a number of laps..", "#1DA1F2");
                        }
                    } else {
                        QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You have not selected a Track..", "#1DA1F2");
                    }
                }
            })
        } else {
            QB.Phone.Notifications.Add("fas fa-flag-checkered", "Racing", "You already have a auction active..", "#1DA1F2");
        }
    });
});

$(document).on('click', '#setup-auction-cancel', function(e) {
    e.preventDefault();

    $(".auctions-overview").animate({
        left: 0 + "vh"
    }, 300);
    $(".auctions-setup").animate({
        left: -30 + "vh"
    }, 300, function() {
        $(".auctions-setup-information-distance").html('Select a Track');
        $(".auctions-setup-information-creator").html('Select a Track');
        $(".auctions-setup-information-wr").html('Select a Track');
        $(".auctions-setup-laps").val("");
        $('.dropdown').find('input').removeAttr('value');
        $('.dropdown').find('span').text('Select a Track');
    });
});

$(document).on('click', '.auctions-leaderboard-item', function(e) {
    e.preventDefault();

    var Data = $(this).data('LeaderboardData');

    $(".auctions-leaderboard-details-block-trackname").html('<i class="fas fa-flag-checkered"></i> ' + Data.RaceName);
    $(".auctions-leaderboard-details-block-list").html("");
    $.each(Data.LastLeaderboard, function(i, leaderboard) {
        var lastname = leaderboard.Holder[1]
        var bestroundtime = "N/A";
        var place = i + 1;
        if (lastname.length > 10) {
            lastname = lastname.substring(0, 10) + "..."
        }
        if (leaderboard.BestLap !== "DNF") {
            bestroundtime = secondsTimeSpanToHMS(leaderboard.BestLap);
        } else {
            place = "DNF"
        }
        var elem = '<div class="row"> <div class="name">' + ((leaderboard.Holder[0]).charAt(0)).toUpperCase() + '. ' + lastname + '</div><div class="time">' + bestroundtime + '</div><div class="score">' + place + '</div> </div>';
        $(".auctions-leaderboard-details-block-list").append(elem);
    });
    $(".auctions-leaderboard-details").fadeIn(200);
});

$(document).on('click', '.auctions-leaderboard-details-back', function(e) {
    e.preventDefault();

    $(".auctions-leaderboard-details").fadeOut(200);
});

$(document).on('click', '.auctions-leaderboards-button', function(e) {
    e.preventDefault();

    $(".auctions-leaderboard").animate({
        left: -30 + "vh"
    }, 300)
    $(".auctions-overview").animate({
        left: 0 + "vh"
    }, 300)
});

$(document).on('click', '#leaderboards-auction', function(e) {
    e.preventDefault();

    $.post('https://qb-phone/GetRacingLeaderboards', JSON.stringify({}), function(Races) {
        if (Races !== null) {
            $(".auctions-leaderboards").html("");
            $.each(Races, function(i, auction) {
                if (auction.LastLeaderboard.length > 0) {
                    var elem = '<div class="auctions-leaderboard-item" id="leaderboard-item-' + i + '"> <span class="auctions-leaderboard-item-name"><i class="fas fa-flag-checkered"></i> ' + auction.RaceName + '</span> <span class="auctions-leaderboard-item-info">Click for more details</span> </div>'
                    $(".auctions-leaderboards").append(elem);
                    $("#leaderboard-item-" + i).data('LeaderboardData', auction);
                }
            });
        }
    });

    $(".auctions-overview").animate({
        left: 30 + "vh"
    }, 300)
    $(".auctions-leaderboard").animate({
        left: 0 + "vh"
    }, 300)
});