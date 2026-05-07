"""
asset_class.py — Asset class enumeration.

Bu repo crypto-only. Enum tek değer içeriyor — diğer asset class'lar
(equity, options) ayrı repolarda yaşar. Kalan kullanım yalnızca
contract'ın korunması için (BaseBrain/BaseBroker/... `asset_class`
property'si).
"""

from enum import Enum


class AssetClass(str, Enum):
    CRYPTO = "crypto"

    @property
    def is_24_7(self) -> bool:
        return self == AssetClass.CRYPTO

    @property
    def supports_pdt(self) -> bool:
        return False

    @property
    def fractional_default(self) -> bool:
        return self == AssetClass.CRYPTO
