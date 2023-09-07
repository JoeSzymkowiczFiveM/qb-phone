QB.Phone.Functions.OpenPayPhone = function() {
    $(".payphone-input").text("");
    QB.Phone.Data.currentApplication = "payphone-call";
    $(".payphone").fadeIn(150);
}

$(document).on('click', '.payphone-dial', function(e){
    var dialNumber = $(this).data('number');
    var NumberInput = $(".payphone-input");
    var CurNumber = $(".payphone-input").text();

    if (dialNumber == "remove") {
        NumberInput.text("");
    } else {
        NumberInput.text(CurNumber + dialNumber);
    }
});

QB.Phone.Functions.PayPhoneClose = function() {
    $.post('https://qb-phone/closePayPhone');
}

$(document).on('click', '.payphone-call', function(e){
    var CurNumber = $(".payphone-input").text();
    
    cData = {
        number: CurNumber,
        name: ''
    }

    $.post('https://qb-phone/CallContactPayphone', JSON.stringify({
        ContactData: cData,
        Anonymous: true,
    }), function(status) {
        if (cData.number !== QB.Phone.Data.PlayerData.charinfo.phone) {
            if (status.IsOnline) {
                if (status.CanCall) {
                    if (!status.InCall) {
                        //if (QB.Phone.Data.AnonymousCall) {
                        QB.Phone.Notifications.Add("fas fa-phone", "Phone", "You have initiated a payphone call!");
                        //}
                        //$(".phone-call-outgoing").css({ "display": "block" });
                        //$(".phone-call-incoming").css({ "display": "none" });
                        //$(".phone-call-ongoing").css({ "display": "none" });
                        //$(".phone-call-outgoing-caller").html(cData.name);
                        //QB.Phone.Functions.HeaderTextColor("white", 400);
                        //QB.Phone.Animations.TopSlideUp('.phone-application-container', 400, -160);
                        // setTimeout(function() {
                        //     $(".phone-app").css({ "display": "none" });
                        //     QB.Phone.Animations.TopSlideDown('.phone-application-container', 400, 0);
                        //     QB.Phone.Functions.ToggleApp("phone-call", "block");
                        // }, 450);

                        CallData.name = cData.name;
                        CallData.number = cData.number;
                        QB.Phone.Data.CallActive = true;

                    } else {
                        QB.Phone.Notifications.Add("fas fa-phone", "Phone", "You are already in a call!");
                    }
                } else {
                    QB.Phone.Notifications.Add("fas fa-phone", "Phone", "This person is on a call!");
                }
            } else {
                QB.Phone.Notifications.Add("fas fa-phone", "Phone", "This person cannot be reached!");
            }
        } else {
            QB.Phone.Notifications.Add("fas fa-phone", "Phone", "You cannot call your own number!");
        }
    });
});

$(document).on('keydown', function() {
    switch (event.keyCode) {
        case 27: // ESC
            if (QB.Phone.Data.currentApplication == "payphone-call") {

                if (QB.Phone.Data.CallActive){
                    $.post('https://qb-phone/CancelOutgoingPayphoneCall');
                } else {
                    $(".payphone").fadeOut(150);
                    QB.Phone.Functions.PayPhoneClose()
                    QB.Phone.Data.currentApplication = null;
                }
            }
    }
});

CancelOutgoingPayphoneCall = function() {
    if (QB.Phone.Data.currentApplication == "payphone-call") {
        $(".call-notifications").animate({
            right: -35 + "vh"
        }, 400);
        setTimeout(function() {
            $("." + QB.Phone.Data.currentApplication + "-app").css({ "display": "none" });
            $(".phone-call-outgoing").css({ "display": "none" });
            $(".phone-call-incoming").css({ "display": "none" });
            $(".phone-call-ongoing").css({ "display": "none" });
            $(".call-notifications").css({ "display": "block" });
        }, 400)
        setTimeout(function() {
            QB.Phone.Functions.ToggleApp(QB.Phone.Data.currentApplication, "none");
        }, 400)
        QB.Phone.Functions.HeaderTextColor("white", 300);

        QB.Phone.Data.CallActive = false;
        QB.Phone.Data.currentApplication = null;
        $(".phone-currentcall-container").css({ "display": "none" });
        $(".payphone").fadeOut(150);
        QB.Phone.Data.currentApplication = null;
    }
}