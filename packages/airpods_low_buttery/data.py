from binascii import hexlify
from dataclasses import dataclass
from enum import Enum

from bleak import BleakScanner

MIN_RSSI = -60
AIRPODS_MANUFACTURER = 76
AIRPODS_DATA_LENGTH = 54


class AirpodsDataFetchFailed(Exception):
    pass


@dataclass
class ChargingData:
    is_charging: bool
    capacity: int


@dataclass
class AirpodsChargingData:
    left: ChargingData
    right: ChargingData
    case: ChargingData


class AirpodsModel(Enum):
    airpods_pro = "e"
    airpods_3 = "3"
    airpods_2 = "f"
    airpods_1 = "2"
    airpods_max = "a"
    unknown = "unknown"

    @classmethod
    def _missing_(cls, value):
        return cls.unknown


@dataclass
class AirpodsData:
    charging: AirpodsChargingData
    model: AirpodsModel
    raw: str


async def get_data():
    raw = await _get_data_hex()
    flip = _is_flipped(raw)

    model = AirpodsModel(chr(raw[7]))

    # Checking left AirPod for availability and storing charge in variable
    status_tmp = int("" + chr(raw[12 if flip else 13]), 16)
    left_status = (
        100 if status_tmp == 10 else (status_tmp * 10 + 5 if status_tmp <= 10 else -1)
    )

    # Checking right AirPod for availability and storing charge in variable
    status_tmp = int("" + chr(raw[13 if flip else 12]), 16)
    right_status = (
        100 if status_tmp == 10 else (status_tmp * 10 + 5 if status_tmp <= 10 else -1)
    )

    # Checking AirPods case for availability and storing charge in variable
    status_tmp = int("" + chr(raw[15]), 16)
    case_status = (
        100 if status_tmp == 10 else (status_tmp * 10 + 5 if status_tmp <= 10 else -1)
    )

    # On 14th position we can get charge status of AirPods
    charging_status = int("" + chr(raw[14]), 16)
    charging_left: bool = (charging_status & (0b00000010 if flip else 0b00000001)) != 0
    charging_right: bool = (charging_status & (0b00000001 if flip else 0b00000010)) != 0
    charging_case: bool = (charging_status & 0b00000100) != 0

    return AirpodsData(
        charging=AirpodsChargingData(
            left=ChargingData(is_charging=charging_left, capacity=left_status),
            right=ChargingData(is_charging=charging_right, capacity=right_status),
            case=ChargingData(is_charging=charging_case, capacity=case_status),
        ),
        model=model,
        raw=raw.decode("utf-8"),
    )


async def _get_data_hex():
    devices = await BleakScanner().discover(return_adv=True)
    for address in devices:
        _, adv_data = devices[address]

        if (
            adv_data.rssi >= MIN_RSSI
            and AIRPODS_MANUFACTURER in adv_data.manufacturer_data
        ):
            data_hex = hexlify(
                bytearray(adv_data.manufacturer_data[AIRPODS_MANUFACTURER])
            )
            if len(data_hex) == AIRPODS_DATA_LENGTH:
                return data_hex
    raise AirpodsDataFetchFailed


def _is_flipped(raw) -> bool:
    return (int("" + chr(raw[10]), 16) & 0x02) == 0
