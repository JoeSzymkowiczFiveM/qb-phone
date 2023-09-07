// DarkWeb JS
let DarkWebName = '';

// $(document).ready(function() {
//     window.addEventListener('message', function(event) {
//         switch (event.data.action) {
//             case "SetVPN":
//                 DarkWebName = event.data
//         }
//     })
// });

$(document).on('click', '.darkweb-slet', function(e) {
    e.preventDefault();

    $(".darkweb-home").animate({
        left: 30 + "vh"
    });
    $(".new-darkweb").animate({
        left: 0 + "vh"
    });
});

/*$(document).on('click', '.darkweb', function (e) {
    e.preventDefault();
    const number = $(this).data("number")
    if (number && number !== "") {
        QB.Phone.Notifications.Add("fa fa-phone-alt", "Phone", "Opening Phone", "default", 2000);
        QB.Phone.Animations.TopSlideUp('.phone-application-container', 400, -160);
        QB.Phone.Animations.TopSlideUp('.' + QB.Phone.Data.currentApplication + "-app", 400, -160);
        setTimeout(function () {
            QB.Phone.Functions.ToggleApp(QB.Phone.Data.currentApplication, "none");
            QB.Phone.Animations.TopSlideDown('.phone-application-container', 300, 0);
            QB.Phone.Functions.ToggleApp("phone", "block");
            QB.Phone.Data.currentApplication = "phone"
            $(".phone-contacts").hide();
            $(".phone-recent").hide();
            $(".phone-keypad").show();
        }, 450)
        $("#phone-keypad-input").text(number)
    }
});*/

$(document).on('click', '#new-darkweb-back', function(e) {
    e.preventDefault();

    $(".darkweb-home").animate({
        left: 0 + "vh"
    });
    $(".new-darkweb").animate({
        left: -30 + "vh"
    });
});

$(document).on('click', '#new-darkweb-submit', function(e) {
    e.preventDefault();
    var darkweb = $(".new-darkweb-textarea").val();
    var name = $(".new-darkweb-name").val();
    $("#darkweb-header-name").html(`@${name}`)
    var date = Date.now()
    $(".new-darkweb-textarea").val("");
    if (darkweb !== "") {
        $(".darkweb-home").animate({
            left: 0 + "vh"
        });
        $(".new-darkweb").animate({
            left: -30 + "vh"
        });
        $.post('https://qb-phone/PostDarkWeb', JSON.stringify({
            msg: darkweb,
            name: name,
            date: date
        }));
    } else {
        QB.Phone.Notifications.Add("fas fa-comment", "DarkWeb", "You can't post an empty message!", "#ff8f1a", 2000);
    }
});

QB.Phone.Functions.RefreshDarkWeb = function(DarkWeb) {
    if (DarkWeb) {
        $(".darkweb-list").html("");
        $.each(DarkWeb, function(i, msg) {
            var element = '<div class="darkweb" data-number="' + msg.number + '"><span class="darkweb-sender">' + msg.name + `</span><p>` + msg.message + '</p></div>';
            $(".darkweb-list").prepend(element);
        });
    } else {
        $(".darkweb-list").html("");
        var element = '<div class="darkweb"><span class="darkweb-sender">There are no messages yet!</span></div>';
        $(".darkweb-list").append(element);
    }
}