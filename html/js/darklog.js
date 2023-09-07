var title = ''
var description = ''
var OpenedDarkLog = null;
var darkLogs = 0

SetupDarkLog = function(data) {
    darkLogs = Object.keys(data).length
    $(".darklogs-list").html("");
    if (Object.keys(data).length > 0) {
        $.each(data, function(i, darklog) {
            
            var element = '<div class="darklog-list" id="darklogid-' + i + '"> <div class="darklog-list-class">D</div> <div class="darklog-list-top">' + darklog.subject + '</div> <div class="darklog-list-middle">' + darklog.message + '</div> </div>';
            $(".darklogs-list").append(element);
            $("#darklogid-" + i).data('id', i);
            $("#darklogid-" + i).data('data', darklog);
        });
    } else if (Object.keys(data).length == 0) {
        $(".darklogs-list").html("");
        var element = '<div class="darklog-list"><span class="darklog-list-middle">There are no messages yet!</span></div>';
        $(".darklogs-list").append(element);
    } 
}

$(document).on('click', '.darklog-list', function(event) {
    event.preventDefault();
    if (darkLogs > 0) {

        $(".darklogs-home").animate({
            left: 30 + "vh"
        });
        $(".new-darklog").animate({
            left: 0 + "vh"
        });

        OpenedDarkLog = $(this).attr('id');
        var DarkLogData = $("#" + OpenedDarkLog).data('data');
        
        if ( OpenedDarkLog ) {    
            $(".new-darklog-name").val(DarkLogData.subject);
            $(".new-darklog-textarea").html(DarkLogData.message);
            $("#new-darklog-header-text").text('DarkLog Details')

            if ( typeof(DarkLogData.button.enabled) !== "undefined" ) {
                $(".new-darklog-footer-item").css({ width: "33%", });
                $("#new-darklog-back").css({ "display": "block" });
                $("#new-darklog-submit").css({ "display": "block" });
            } else {
                $(".new-darklog-footer-item").css({ width: "50%", });
                $("#new-darklog-back").css({ "display": "block" });
                $("#new-darklog-submit").css({ "display": "none" });
            } 
        }
    }
});

$(document).on('click', '#new-darklog-back', function(e) {
    e.preventDefault();

    $(".darklogs-home").animate({left: 0 + "vh"});
    $(".new-darklog").animate({left: -30 + "vh"});
    OpenedDarkLog = null;
});

$(document).on('click', '#new-darklog-submit', async function(e) {
    e.preventDefault();
    
    const darklogId = OpenedDarkLog.split("darklogid-");
    var DarkLogData = $("#" + OpenedDarkLog).data('data');

    $(".darklogs-home").animate({left: 0 + "vh"});
    $(".new-darklog").animate({left: -30 + "vh"});

    let result = await $.post(
        `https://${GetParentResourceName()}/AcceptDarkLogButton`,
        JSON.stringify({
            buttonEvent: DarkLogData.button.buttonEvent,
            buttonData: DarkLogData.button.buttonData,
            id: darklogId[1],
        })
    );
    OpenedDarkLog = null;
    SetupDarkLog(result)
});

$(document).on('click', '#new-darklog-delete', async function(e) {
    e.preventDefault();
    
    const darklogId = OpenedDarkLog.split("darklogid-");


    $(".darklogs-home").animate({left: 0 + "vh"});
    $(".new-darklog").animate({left: -30 + "vh"});

    let result = await $.post(
        `https://${GetParentResourceName()}/DeleteDarkLogButton`,
        JSON.stringify({
            id: darklogId[1],
        })
    );
    OpenedDarkLog = null;
    SetupDarkLog(result)
});