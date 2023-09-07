var OpenedId = null;

$(document).on('click', '.notes-add', function(e) {
    e.preventDefault();

    $(".notes-home").animate({
        left: 30 + "vh"
    });
    $(".new-note").animate({
        left: 0 + "vh"
    });
    $(".new-note-name").val('');
    $(".new-note-textarea").val('');
    $("#new-note-header-text").text('Add Note')

    $(".new-note-footer-item").css({
        width: "50%",
    });
    $("#new-note-delete").css({ "display": "none" });
});

$(document).on('click', '#new-note-back', function(e) {
    e.preventDefault();

    $(".notes-home").animate({
        left: 0 + "vh"
    });
    $(".new-note").animate({
        left: -30 + "vh"
    });
});

$(document).on('click', '#new-note-delete', function(e) {
    e.preventDefault();

    $.post('https://qb-phone/DeleteNote', JSON.stringify({
        id: OpenedId,
    }));

    $(".notes-home").animate({
        left: 0 + "vh"
    });
    $(".new-note").animate({
        left: -30 + "vh"
    });
});

$(document).on('click', '#new-note-submit', function(e) {
    e.preventDefault();
    
    var note = $(".new-note-textarea").val();
    var name = $(".new-note-name").val();

    if (note !== "") {
        $(".notes-home").animate({
            left: 0 + "vh"
        });
        $(".new-note").animate({
            left: -30 + "vh"
        });
        if ( $("#new-note-header-text").text() === 'Add Note' ) {
            $.post('https://qb-phone/PostNote', JSON.stringify({
                body: note,
                title: name,
                //date: date
            }));
        } else if ( $("#new-note-header-text").text() === 'Edit Note') {
            $.post('https://qb-phone/EditNote', JSON.stringify({
                body: note,
                title: name,
                id: OpenedId,
            }));
        }
        
    } else {
        QB.Phone.Notifications.Add("fas fa-comment", "Notes", "You can't post an empty note!", "#ff8f1a", 2000);
    }
});

$(document).on('click', '.note', function(e) {
    
    $(".notes-home").animate({
        left: 30 + "vh"
    });
    $(".new-note").animate({
        left: 0 + "vh"
    });

    var Id = $(this).attr('id');
    var NoteData = $("#"+Id).data('NoteData');
    if ( Id ) { 
        OpenedId = Id.substring(5)
        
        $(".new-note-name").val(NoteData.title);
        $(".new-note-textarea").val(NoteData.body);
        $("#new-note-header-text").text('Edit Note')

        $(".new-note-footer-item").css({
            width: "33%",
        });
        $("#new-note-delete").css({ "display": "block" });
    } else {
        $(".new-note-name").val('');
        $(".new-note-textarea").val('');
        $("#new-note-header-text").text('Add Note')

        $(".new-note-footer-item").css({
            width: "50%",
        });
        $("#new-note-delete").css({ "display": "none" });
    }
});

RefreshNotes = function(Notes) {
    $(".notes-list").html("");
    if (Object.keys(Notes).length > 0) {
        $.each(Notes, function(i, note) {
            var element = '<div class="note" id="note-'+note.id+'"><span class="note-sender">' + truncateNotes(note.title) + `</span><p>` + truncateNotes(note.body) + '</p></div>';
            $(".notes-list").prepend(element);
            $("#note-"+note.id).data('NoteData', note);
        });
    } else if (Object.keys(Notes).length == 0) {
        $(".notes-list").html("");
        var element = '<div class="note"><span class="note-sender">There are no notes yet!</span></div>';
        $(".notes-list").append(element);
    }
}

function truncateNotes(input) {
    if (input.length > 30) {
        return input.substring(0, 30) + '...';
    }
    return input;
};