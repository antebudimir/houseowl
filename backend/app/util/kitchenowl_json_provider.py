import enum
from flask.json.provider import DefaultJSONProvider
from datetime import date, datetime, timezone


class KitchenOwlJSONProvider(DefaultJSONProvider):
    def default(self, o):  # type: ignore[assignment]
        # NOTE: datetime must be checked first, it is a subclass of date and
        # date.replace() does not accept tzinfo.
        if isinstance(o, datetime):
            return int(round(o.replace(tzinfo=timezone.utc).timestamp() * 1000))
        if isinstance(o, date):
            return int(
                round(
                    datetime(
                        o.year, o.month, o.day, tzinfo=timezone.utc
                    ).timestamp()
                    * 1000
                )
            )
        if isinstance(o, enum.Enum):
            return int(o.value)

        return super().default(o)
