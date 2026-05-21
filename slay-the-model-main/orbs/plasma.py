from engine.runtime_api import add_action
from actions.combat import GainEnergyAction
from orbs.base import Orb

class PlasmaOrb(Orb):
    passive_timing = "turn_start"
    
    def __init__(self):
        self.passive_energy_gain = 1
        self.evoke_energy_gain = 2

    def on_passive(self) -> None:
        add_action(GainEnergyAction(energy=self.passive_energy_gain))

    def on_evoke(self) -> None:
        add_action(GainEnergyAction(energy=self.evoke_energy_gain))
