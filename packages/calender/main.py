import sys
from icalendar import Calendar
from datetime import datetime, date, timedelta
import pytz


def get_events_today(ics_file):
    # Get current time in local timezone
    local_now = datetime.now().astimezone() + timedelta(days=4)
    local_tz = local_now.tzinfo
    today_date = local_now.date()
    start_of_today = local_now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_today = start_of_today + timedelta(days=1)

    # Read the ics file
    with open(ics_file, "rb") as f:
        cal = Calendar.from_ical(f.read())

    events_today = []

    for component in cal.walk():
        if component.name == "VEVENT":
            dtstart = component.get("dtstart").dt
            category = component.get("categories").cats[0]
            location = component.get("location")
            try:
                dtend = component.get("dtend").dt
            except:
                dtend = dtstart  # Handle events without dtend

            # Check if all-day event
            if isinstance(dtstart, date) and not isinstance(dtstart, datetime):
                event_start_date = dtstart
                event_end_date = dtend if isinstance(dtend, date) else dtstart
                if event_start_date <= today_date < event_end_date:
                    summary = str(component.get("summary", "No title"))
                    events_today.append(
                        {
                            "summary": summary,
                            "all_day": True,
                            "start": dtstart,
                            "end": dtend,
                        }
                    )
            else:
                # Handle datetime events
                if not dtstart.tzinfo:
                    dtstart = dtstart.replace(tzinfo=pytz.UTC)
                if not dtend.tzinfo:
                    dtend = dtend.replace(tzinfo=pytz.UTC)

                event_start = dtstart.astimezone(local_tz)
                event_end = dtend.astimezone(local_tz)

                if (event_start < end_of_today) and (event_end > start_of_today):
                    summary = str(component.get("summary", "No title"))
                    events_today.append(
                        {
                            "summary": summary,
                            "category": category,
                            "all_day": False,
                            "start": event_start,
                            "end": event_end,
                        }
                    )

    return events_today


def format_output(event: dict) -> str:
    start_time = event["start"].strftime("%H:%M")
    end_time = event["end"].strftime("%H:%M")
    summary = event["summary"]
    summary = summary.split("Vorlesung und Labor")[-1]
    summary = summary.split(":")[-1]
    summary = summary.split("- (")[0]
    summary = summary.split("(")[0].strip()
    summary = summary.replace("Vorlesung", "")
    # summary = summary.split("-")[0].strip()
    # return f"{event['category']}: {summary} ({start_time} - {end_time})"
    return f"{start_time} {event['category']}: {summary}"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ics_parser.py <path_to_ics_file>")
        sys.exit(1)

    events = get_events_today(sys.argv[1])

    if not events:
        print("No events today.")
    else:
        # print("Today's Events:")
        for event in events:
            print(format_output(event))
