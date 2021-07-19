import "commonReactions/all.dsl";
context
{
    input phone: string;
    desired_weekday: string = "";
    what_day: string = "";
    see_you_soon: string = "";
}

// Прохождение IVR Zoom
// Если в ноде root будет определён автоответчик, то Даша начнёт прохождение IVR (нужно вручную в строке 31 указать идентификатор конференции)
// если в ноде root сказать "алло" то Даша начнёт разговор сразу

start node root
{
    do
    {
        #connectSafe($phone);
        digression disable{answering_machine, what_day, how_much};
        wait *;
    }
    transitions
    {
        transition0: goto IVR1 on #messageHasIntent("answering_machine") priority 500;
        transition1: goto greeting on #messageHasIntent("ping");
    }
}
node IVR1
{
    do
    {
        #sendDTMF ("81246226388#");
        wait *;
    }
    transitions
    {
        transition0: goto IVR2 on true priority 500;
    }
}
node IVR2
{
    do
    {
        #sendDTMF ("#");
        wait *;
    }
        transitions
    {
        transition0: goto greeting on #messageHasIntent("ping") priority 500;
    }
}

node greeting
{
    do
    {
        digression enable {answering_machine, what_day, how_much};
        #say("intro");
        wait *;
    }
}

digression schedule_haircut
{
    conditions
    {
        on #messageHasIntent("schedule_haircut");
    }
    do
    {
        #say("haircut_confirm");
        wait *;
    }
    transitions
    {
        schedule_haircut_day: goto schedule_haircut_day on #messageHasSentiment("positive");
        this_is_barbershop: goto this_is_barbershop on #messageHasSentiment("negative");
    }
}

node schedule_haircut_day
{
    do
    {
        #say("day");
        wait *;
    }
}

node this_is_barbershop
{
    do
    {
        #say("bye_strange");
        exit;
    }
}

digression schedule_weekday
{
    conditions
    {
        on #messageHasData("day_of_week");
    }
    //за распознавание дня недели отвечают entities в файле intents.json - entities специально созданы для распознавания улиц, городов, имён, дней недели и т.п.
    do
    {
        #say("day_of_week");

        var weekday: string? = null;
        var schedule_weekday: string = $desired_weekday;
        var day_of_week = #messageGetData("day_of_week");
        for (var d in day_of_week) {
            if (d?.value != $desired_weekday) {
                set weekday = d?.value;
            }
        }
        if (weekday is not null) {
            set $desired_weekday = weekday; 
        }
        
        if(weekday == "понедельник")
        {
            set schedule_weekday = "schedule_weekday_monday"; set $what_day = "what_day_monday"; set $see_you_soon = "see_you_soon_monday";
        }
        else if(weekday == "вторник")
        {
            set schedule_weekday = "schedule_weekday_tuesday"; set $what_day = "what_day_tuesday"; set $see_you_soon = "see_you_soon_tuesday";
        }
        else if(weekday == "среда")
        {
            set schedule_weekday = "schedule_weekday_wednesday"; set $what_day = "what_day_wednesday"; set $see_you_soon = "see_you_soon_wednesday";
        }
        else if(weekday == "четверг")
        {
            set schedule_weekday = "schedule_weekday_thursday"; set $what_day = "what_day_thursday"; set $see_you_soon = "see_you_soon_thursday";
        }
        else if(weekday == "пятница")
        {
            set schedule_weekday = "schedule_weekday_friday"; set $what_day = "what_day_friday"; set $see_you_soon = "see_you_soon_friday";
        }
        else if(weekday == "суббота")
        {
            set schedule_weekday = "schedule_weekday_saturday"; set $what_day = "what_day_saturday"; set $see_you_soon = "see_you_soon_saturday";
        }
        else if(weekday == "воскресенье")
        {
            set schedule_weekday = "schedule_weekday_sunday"; set $what_day = "what_day_sunday"; set $see_you_soon = "see_you_soon_sunday";
        }
        
        #say("schedule_weekday",
        {
            desired_weekday: schedule_weekday
        }
        );
        #say("something_else");
        wait *;
    }
    transitions
    {
        can_help: goto can_help on #messageHasSentiment("positive");
        confirm_appointment: goto confirm_appointment on #messageHasSentiment("negative");
    }
}

node can_help
{
    do
    {
        #say("how_can_i_help");
        wait *;
    }
}

node confirm_appointment
{
    do
    {
        #say("see_you_soon",
        {
            see_you_soon: $see_you_soon
        }
        );
        exit;
    }
}

digression cancel_appt
{
    conditions
    {
        on #messageHasIntent("cancel_appt");
    }
    do
    {
        #say("cancel_booking");
        wait *;
    }
    transitions
    {
        cancel_appt_do: goto cancel_appt_do on #messageHasSentiment("positive");
        confirm_appointment: goto confirm_appointment on #messageHasSentiment("negative");
    }
}

digression how_much
{
    conditions
    {
        on #messageHasIntent("how_much");
    }
    do
    {
        #say("cost");
        wait *;
    }
}

digression what_day
{
    conditions
    {
        on #messageHasIntent("what_day");
    }
    do
    {
        #say("what_day",
        {
            what_day: $what_day
        }
        );
        wait *;
    }
    transitions
    {
        confirm_appointment: goto confirm_appointment on #messageHasSentiment("negative");
    }
}

node cancel_appt_do
{
    do
    {
        #say("booking_cancelled");
        wait *;
    }
    transitions
    {
        schedule_haircut_day: goto schedule_haircut_day on #messageHasSentiment("positive");
        bye_bye: goto bye_bye on #messageHasSentiment("negative");
    }
}

node bye_bye
{
    do
    {
        #say("bye_fail");
        exit;
    }
}

digression bye
{
    conditions
    {
        on #messageHasIntent("bye");
    }
    do
    {
        #say("bye_win");
        exit;
    }
}
