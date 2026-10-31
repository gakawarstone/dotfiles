import importlib.util
import io
import os
import time
import unittest
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import mock_open, patch
import icalendar
import pytz


with patch("builtins.open", mock_open(read_data="https://example.com/calendar.ics")):
    spec = importlib.util.spec_from_file_location("studipcal_main", Path(__file__).with_name("main.py"))
    main = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(main)


class DatetimeMeta(type):
    def __instancecheck__(cls, instance):
        return isinstance(instance, datetime)


class FixedDatetime(datetime, metaclass=DatetimeMeta):
    @classmethod
    def now(cls, tz=None):
        return cls(2026, 10, 31, 12, tzinfo=timezone.utc)


class CalendarTest(unittest.TestCase):
    def test_read_and_format_events_with_and_without_categories(self):
        calendar = b"\r\n".join([
            b"BEGIN:VCALENDAR",
            b"VERSION:2.0",
            b"PRODID:-//StudIP//Calendar//EN",
            b"BEGIN:VEVENT",
            b"UID:all-day-with-category@example.com",
            b"DTSTART;VALUE=DATE:20261031",
            b"DTEND;VALUE=DATE:20261101",
            b"SUMMARY:Campus closed",
            b"LOCATION:Campus",
            b"CATEGORIES:Holiday",
            b"END:VEVENT",
            b"BEGIN:VEVENT",
            b"UID:all-day-no-category@example.com",
            b"DTSTART;VALUE=DATE:20261030",
            b"DTEND;VALUE=DATE:20261101",
            b"SUMMARY:Conference",
            b"LOCATION:Auditorium",
            b"END:VEVENT",
            b"BEGIN:VEVENT",
            b"UID:timed-no-category@example.com",
            b"DTSTART:20261031T090000Z",
            b"DTEND:20261031T100000Z",
            b"SUMMARY:Project meeting",
            b"LOCATION:Room 101",
            b"END:VEVENT",
            b"BEGIN:VEVENT",
            b"UID:timed-with-category@example.com",
            b"DTSTART:20261031T110000Z",
            b"DTEND:20261031T120000Z",
            b"SUMMARY:Lecture",
            b"LOCATION:Room 102",
            b"CATEGORIES:Course,Other",
            b"END:VEVENT",
            b"BEGIN:VEVENT",
            b"UID:previous-day@example.com",
            b"DTSTART;VALUE=DATE:20261030",
            b"DTEND;VALUE=DATE:20261031",
            b"SUMMARY:Yesterday",
            b"END:VEVENT",
            b"END:VCALENDAR",
            b"",
        ])
        old_tz = os.environ.get("TZ")
        self.addCleanup(self.restore_timezone, old_tz)
        os.environ["TZ"] = "UTC"
        time.tzset()
        with patch.object(main, "datetime", FixedDatetime), patch.object(
            main, "urlopen", return_value=io.BytesIO(calendar)
        ):
            events = main.get_events_today()

        self.assertEqual([event["summary"] for event in events], [
            "Campus closed", "Conference", "Project meeting", "Lecture"
        ])
        self.assertEqual([main.format_output(event) for event in events], [
            "00:00 Campus Holiday: Campus closed",
            "00:00 Auditorium Conference",
            "09:00 Room 101 Project meeting",
            "11:00 Room 102 Course: Lecture",
        ])

    @staticmethod
    def restore_timezone(old_tz):
        if old_tz is None:
            os.environ.pop("TZ", None)
        else:
            os.environ["TZ"] = old_tz
        time.tzset()


if __name__ == "__main__":
    unittest.main()
