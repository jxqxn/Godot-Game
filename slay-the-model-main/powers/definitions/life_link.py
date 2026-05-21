"""Life Link power for Darkling death-link behavior."""

from powers.base import Power, StackType
from utils.registry import register


@register("power")
class LifeLinkPower(Power):
    """Marker power: linked enemies prevent Darkling death while alive."""

    name = "Life Link"
    stack_type = StackType.PRESENCE
    is_buff = True

    def __init__(self, amount: int = 1, duration: int = -1, owner=None):
        super().__init__(amount=amount, duration=duration, owner=owner)
