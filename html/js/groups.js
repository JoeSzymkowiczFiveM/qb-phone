let GroupID = 0;
let isInGroup = false;
let isGroupLeader = false;
let CurrentStage = "WAITING";
let GroupMembers = [];
let GroupTasks = [];
let GroupRequests = [];

$(document).on('click', '#create-group', async function(e) {
    e.preventDefault();

    $(".groups-homescreen").animate({
        left: 30+"vh"
    }, 200);
    $(".groups-detailscreen").animate({
        left: 0+"vh"
    }, 200);

    if (!isInGroup) {
        $(".groups-vehicles").html("");
        let result = await $.post('https://ps-playergroups/group-create');
        CurrentStage = "WAITING"
        GroupID = result.groupID
        $("#create-group").html('<i class="fa-solid fa-user-group"></i><span class="groups-general-action-title">Open Group</span><span class="groups-general-action-description">View your group.</span></div>');
        isGroupLeader = true
        isInGroup = true
        GroupMembers = [];
        GroupMembers.push(result)
        if (result != false) {
            $.post('https://ps-playergroups/group-created', JSON.stringify({
                GroupID : GroupID,
                status : CurrentStage,
                leader: isGroupLeader,
            }));
            $.each(GroupMembers, function(i, member){
                var Element = '<div class="groups-vehicle" id="member-'+member.id+'"> <span class="groups-vehicle-firstletter">'+member.name.charAt(0)+'</span> <span class="groups-vehicle-name">'+member.name+'</span> </div>';
                
                $(".groups-vehicles").append(Element);
                $("#member-"+member.id).data('MemberData', member);
            });
        } else {
            console.log("Unable to create group");
        }
    }
});

$(document).on('click', '#join-group', async function(e) {
    e.preventDefault();
    
    let Groups = await $.post('https://qb-phone/SetupAvailableGroups');
    SetupAvailableGroups(Groups);

    $(".groups-homescreen").animate({
        left: 30+"vh"
    }, 200);
    $(".groups-listscreen").animate({
        left: 0+"vh"
    }, 200);
});

$(document).on('click', '#leave-group', async function(e) {
    e.preventDefault();

    if (isInGroup) {
        if (isGroupLeader) {
            isGroupLeader = false
            $.post('https://ps-playergroups/group-destroy');
            
        } else {
            $.post('https://ps-playergroups/group-leave', JSON.stringify({groupID : GroupID }));
        }

    }
    GroupCleanup()

    $(".groups-homescreen").animate({
        left: 00+"vh"
    }, 200);
    $(".groups-detailscreen").animate({
        left: -30+"vh"
    }, 200);
});

$(document).on('click', '#groups-details-footer', function(e){
    e.preventDefault();

    $(".groups-homescreen").animate({
        left: 00+"vh"
    }, 200);
    $(".groups-detailscreen").animate({
        left: -30+"vh"
    }, 200);
});

$(document).on('click', '#groups-list-footer', function(e){
    e.preventDefault();

    $(".groups-homescreen").animate({
        left: 00+"vh"
    }, 200);
    $(".groups-listscreen").animate({
        left: -30+"vh"
    }, 200);
});

$(document).on('click', '#groups-requests-footer', function(e){
    e.preventDefault();

    $(".groups-app-header").html('Groups Management');

    $(".groups-detailscreen").animate({
        left: 00+"vh"
    }, 200);
    $(".groups-requestscreen").animate({
        left: -30+"vh"
    }, 200);
});

$(document).on('click', '.groups-listitem', function(e){
    e.preventDefault();

    var Id = $(this).attr('id');
    var GroupData = $("#"+Id).data('GroupData');

    $.post('https://ps-playergroups/request-join', JSON.stringify({groupID : GroupData.id }));
});

$(document).on('click', '#requests-group', async function(e) {
    e.preventDefault();
    $(".groups-requestdetails").html("");
    
    if (isGroupLeader) {
        $(".groups-app-header").html('Groups Management - Requests');
        let temp = []
        let result = await $.post('https://ps-playergroups/view-requests', JSON.stringify({groupID : GroupID }));
        $.each(result, function(index, value) {
            temp.push(value)
        });
        GroupRequests = temp
        $.each(GroupRequests, function(i, request){
            var Element = '<div class="groups-requestitem" id="'+i+'" requesterid="'+request.id+'"> <span class="groups-requestitem-firstletter">'+request.name.charAt(0)+'</span> <span class="groups-requestitem-name">'+request.name+'</span><div class="groups-request-buttons"> <i class="fas fa-check-circle accept-group-request"></i> <i class="fas fa-times-circle decline-group-request"></i></div> </div>';
            
            $(".groups-requestdetails").append(Element);
            $("#group-"+i).data('RequestData', request);
        });

        $(".groups-detailscreen").animate({
            left: 30+"vh"
        }, 200);
        $(".groups-requestscreen").animate({
            left: 0+"vh"
        }, 200);
    }
});

$(document).on('click', '#group-tasks', async function(e) {
    e.preventDefault();
    $(".groups-requestdetails").html("");
    
});

$(document).on('click', '.accept-group-request', function(event) {
    event.preventDefault();

    var id = $(this).parent().parent().attr('id');
    var RequesterId = $(this).parent().parent().attr('requesterid');

    $("#" + id).animate({
        left: 30 + "vh",
    }, 300, function() {
        setTimeout(function() {
            $("#" + id).remove();
        }, 100);
    });

    RequestAccept(RequesterId)
});

$(document).on('click', '.decline-group-request', function(event) {
    event.preventDefault();

    var id = $(this).parent().parent().attr('id');
    var RequesterId = $(this).parent().parent().attr('requesterid');

    $("#" + id).animate({
        left: 30 + "vh",
    }, 300, function() {
        setTimeout(function() {
            $("#" + id).remove();
        }, 100);
    });

    RequestDeny(RequesterId)
});

function UpdateGroup(data, type) {
    if (type === "leave") {
    } else if (type === "setStage") {
        CurrentStage = data.stage
        $.post('https://ps-playergroups/update-status', JSON.stringify({status : this.CurrentStage }));
    } else if (type === "groupDestroy") {
        isInGroup = false
        isGroupLeader = false 
        GroupCleanup()
    } else if (type === "update") {
        
        $(".groups-vehicles").html("");
        GroupMembers = []
        let temp = []
        $.each(data, function(index, value) {
            temp.push(value)
        });
        GroupMembers = temp
        $.each(GroupMembers, function(i, member){
            var Element = '<div class="groups-vehicle" id="member-'+member.id+'"> <span class="groups-vehicle-firstletter">'+member.name.charAt(0)+'</span> <span class="groups-vehicle-name">'+member.name+'</span> </div>';
            
            $(".groups-vehicles").append(Element);
            $("#member-"+member.id).data('MemberData', member);
        });
        if (!isInGroup) {
            isInGroup = true
        }
    }
}

function JoinGroup(data) {
    isInGroup = true
    GroupID = data.groupID
    $("#create-group").html('<i class="fa-solid fa-user-group"></i><span class="groups-general-action-title">Open Group</span><span class="groups-general-action-description">View your group.</span></div>');
}

RequestDeny = function(id) {
    if (isGroupLeader) {
        $.post('https://ps-playergroups/request-deny', JSON.stringify({player : Number(id), groupID : GroupID}));
    }
}

RequestAccept = function(id) {
    if (isGroupLeader) {
        $.post('https://ps-playergroups/request-accept', JSON.stringify({player : Number(id), groupID : GroupID}));
    }
}

MemberKick = function(id) {
    if (isGroupLeader) {
        $.post('https://ps-playergroups/member-kick', JSON.stringify({player : Number(id), groupID : GroupID}));
    }
}

SetupAvailableGroups = function(Groups) {
    $(".groups-list").html("");
    if (Groups != null) {
        $.each(Groups, function(i, group){
            if (group.id !== GroupID) {
                var Element = '<div class="groups-listitem" id="group-'+i+'"> <span class="groups-listitem-firstletter">'+group.name.charAt(0)+'</span> <span class="groups-listitem-name">'+group.name+'</span> </div>';
                
                $(".groups-list").append(Element);
                $("#group-"+i).data('GroupData', group);
            }
        });
    }
}

GroupCleanup = function() {
    GroupMembers = []
    GroupTasks = []
    CurrentStage = "None"
    GroupID = 0
    $("#create-group").html('<i class="fa-solid fa-person-circle-plus"></i><span class="groups-general-action-title">Create Group</span><span class="groups-general-action-description">Create a new group.</span></div>');
    isInGroup = false
    $(".groups-vehicles").html("");
    $.post('https://ps-playergroups/group-cleanup');
}

