from expungeservice.models.charge_types.felony_class_b import FelonyClassB
from expungeservice.models.expungement_result import EligibilityStatus

from tests.factories.charge_factory import ChargeFactory
from tests.models.test_charge import Dispositions


def test_class_b_felony_164057():
    charge = ChargeFactory.create(
        name="Aggravated theft in the first degree",
        statute="164.057",
        level="Felony Class B",
        disposition=Dispositions.CONVICTED,
    )

    assert isinstance(charge, FelonyClassB)
    assert charge.expungement_result.type_eligibility.status is EligibilityStatus.NEEDS_MORE_ANALYSIS
    assert charge.expungement_result.type_eligibility.reason == "Further Analysis Needed"


def test_class_felony_is_added_to_b_felony_attribute():
    charge = ChargeFactory.create(
        name="Aggravated theft in the first degree", statute="164.057", level="Felony Class B"
    )

    assert isinstance(charge, FelonyClassB)
