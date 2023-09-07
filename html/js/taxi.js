$(document).on('click', '#get-taxinpc', function(e) {
    e.preventDefault();
    //$.post('https://qb-phone/CallNPCTaxi', JSON.stringify({}))
    //QB.Phone.Functions.Close();
    $.post('https://qb-phone/GetTaxiPlayers', JSON.stringify({}), function(taxiPlayers) {
        //QB.Phone.Functions.LoadBankInvoices(invoices);
        

        if (taxiPlayers.length > 0 ) {
            console.log(1)
            var random = Math.floor(Math.random() * taxiPlayers.length);
            var cData = {
                number: taxiPlayers[random].phone,
                name: taxiPlayers[random].name
            }
            $.post('https://qb-phone/CallContact', JSON.stringify({
                ContactData: cData,
                Anonymous: false,
            }), function(status) {
                if (cData.number !== QB.Phone.Data.PlayerData.charinfo.phone) {
                    if (status.IsOnline) {
                        if (status.CanCall) {
                            if (!status.InCall) {
                                $(".phone-call-outgoing").css({ "display": "block" });
                                $(".phone-call-incoming").css({ "display": "none" });
                                $(".phone-call-ongoing").css({ "display": "none" });
                                $(".phone-call-outgoing-caller").html(cData.name);
                                QB.Phone.Functions.HeaderTextColor("white", 400);
                                QB.Phone.Animations.TopSlideUp('.phone-application-container', 400, -160);
                                setTimeout(function() {
                                    $(".taxi-app").css({ "display": "none" });
                                    QB.Phone.Animations.TopSlideDown('.phone-application-container', 400, 0);
                                    QB.Phone.Functions.ToggleApp("phone-call", "block");
                                }, 450);

                                CallData.name = cData.name;
                                CallData.number = cData.number;

                                QB.Phone.Data.currentApplication = "phone-call";
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
        } else {
            console.log(2)
            $.post('https://qb-phone/CallNPCTaxi', JSON.stringify({}))
            QB.Phone.Functions.Close();
        }
    });
});